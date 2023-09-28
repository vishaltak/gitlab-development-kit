# frozen_string_literal: true

require 'fileutils'
require 'forwardable'
require 'json'
require 'set'

require_relative 'postgresql'

module GDK
  class PostgresqlUpgrader
    extend Forwardable

    POSTGRESQL_VERSIONS = %w[14 13 12 11 10 9.6].freeze

    def_delegators :postgresql, :current_data_dir, :current_version, :upgrade_needed?

    def initialize(target_version = GDK::Postgresql.target_version_major)
      @target_version = target_version
    end

    def upgrade!
      check!

      success = true

      unless upgrade_needed?(target_version)
        GDK::Output.success "'#{current_data_dir}' is already compatible with PostgreSQL #{target_version}."
        return
      end

      begin
        gdk_stop
        init_db_in_target_path
        pgvector_setup
        rename_current_data_dir
        pg_upgrade
        promote_new_db
        gdk_reconfigure
        pg_replica_upgrade('replica')
        pg_replica_upgrade('replica_2')
      rescue StandardError => e
        success = false
        GDK::Output.error "An error occurred: #{e}"
        GDK::Output.warn 'Rolling back..'
        rename_current_data_dir_back
      end

      if success
        GDK::Output.success "Upgraded '#{current_data_dir}' from PostgreSQL #{current_version} to #{target_version}."
      else
        GDK::Output.warn "Upgrade failed. Rolled back to the original PostgreSQL #{current_version}."
      end
    end

    def bin_path(version = target_version)
      raise "Invalid PostgreSQL version #{version}" unless available_versions.key?(version)

      available_versions[version]
    end

    private

    attr_reader :target_version

    def check!
      GDK::Output.info "Available PostgreSQL versions: #{available_versions}"

      GDK::Output.abort "Unable to find target PostgreSQL version #{target_version}" unless available_versions.include?(target_version)
      GDK::Output.abort "Unable to find current PostgreSQL version #{current_version}" unless available_versions.include?(current_version)
    end

    def postgresql
      @postgresql ||= GDK::Postgresql.new
    end

    def renamed_current_data_dir
      @renamed_current_data_dir ||= "#{current_data_dir}.#{current_version}.#{Time.now.to_i}"
    end

    def target_path
      @target_path ||= "#{current_data_dir}.#{target_version}.#{Time.now.to_i}"
    end

    def gdk_stop
      run!('gdk stop', config.gdk_root)
    end

    def init_db_in_target_path
      cmd = "#{initdb_bin(target_version)} --locale=C -E utf-8 #{target_path}"
      GDK::Output.info "Initializing '#{target_path}' for PostgreSQL #{target_version}.."
      run_in_tmp!(cmd)
    end

    def rename_current_data_dir
      GDK::Output.info "Renaming #{current_data_dir} to #{renamed_current_data_dir}"
      FileUtils.mv(current_data_dir, renamed_current_data_dir)
    end

    def rename_current_data_dir_back
      return unless File.exist?(renamed_current_data_dir)

      GDK::Output.info "Renaming #{renamed_current_data_dir} to #{current_data_dir}"
      FileUtils.mv(renamed_current_data_dir, current_data_dir)
    end

    def pgvector_setup
      return unless config.gitlab.rails.databases.embedding.enabled?

      GDK::Output.info "Running 'make pgvector-setup'.."
      run!('make pgvector-setup', config.gdk_root)
    end

    def pg_upgrade
      cmd = "#{pg_upgrade_bin(target_version)} \
      --old-bindir #{bin_path(current_version)} \
      --new-bindir #{bin_path(target_version)} \
      --old-datadir #{renamed_current_data_dir} \
      --new-datadir #{target_path}"

      GDK::Output.info "Upgrading '#{renamed_current_data_dir}' (PostgreSQL #{current_version}) to '#{target_path}' PostgreSQL #{target_version}.."
      run_in_tmp!(cmd)
    end

    def remove_secondary_data?(replica_name)
      return unless config.postgresql.public_send(replica_name).enabled? # rubocop:disable GitlabSecurity/PublicSend

      GDK::Output.warn("We're about to remove the old '#{replica_name}' database data because we will be replacing it with the primary database data.")

      return true if ENV.fetch('PG_AUTO_UPDATE', 'false') == 'true' || !GDK::Output.interactive?

      GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
    end

    def pg_replica_upgrade(replica_name)
      return true unless remove_secondary_data?(replica_name)

      pg_primary_dir = config.gdk_root.join('postgresql')
      pg_secondary_data_dir = config.gdk_root.join("postgresql-#{replica_name.tr('_', '-')}/data")

      GDK::Output.info 'Removing the old secondary database data...'
      run!("rm -rf #{pg_secondary_data_dir}", config.gdk_root)

      replication_user = config.postgresql.replication_user

      GDK::Output.info 'Copying data from primary to secondary...'
      cmd = "pg_basebackup -R -h #{pg_primary_dir} -D #{pg_secondary_data_dir} -P -U #{replication_user} --wal-method=fetch"
      run!(cmd, config.gdk_root)
    end

    def promote_new_db
      GDK::Output.info "Promoting newly-creating database from '#{target_path}' to '#{current_data_dir}'"
      FileUtils.mv(target_path, current_data_dir)
    end

    def gdk_reconfigure
      GDK::Output.info "Running 'gdk reconfigure'.."
      run!('gdk reconfigure', config.gdk_root)
    end

    def initdb_bin(version)
      File.join(bin_path(version), 'initdb')
    end

    def pg_upgrade_bin(version)
      File.join(bin_path(version), 'pg_upgrade')
    end

    def available_versions
      @available_versions ||=
        if asdf?
          asdf_available_versions
        elsif rtx?
          rtx_available_versions
        elsif brew?
          brew_cellar_available_versions.transform_keys(&:to_i)
        elsif apt?
          apt_available_versions
        else
          abort 'Only Homebrew, asdf, rtx, and apt based Linux systems supported.'
        end
    end

    def asdf?
      run(%w[asdf help]) != ''
    end

    def rtx?
      run(%w[rtx help]) != ''
    end

    def brew?
      run(%w[brew help]) != ''
    end

    def apt?
      run(%w[apt-cache help]) != ''
    end

    def asdf_available_versions
      lines = run(%w[asdf list postgres])
      return {} if lines.empty?

      current_asdf_data_dir = ENV.fetch('ASDF_DATA_DIR', "#{Dir.home}/.asdf")
      versions = lines.split.map { |x| Gem::Version.new(x) }.sort.reverse

      asdf_package_paths(current_asdf_data_dir, versions)
    end

    def rtx_available_versions
      lines = run(%w[rtx list -i -c --json postgres])
      return {} if lines.empty?

      current_asdf_data_dir = ENV.fetch('RTX_CACHE_DIR', "#{Dir.home}/.local/share/rtx")
      versions = JSON.parse(lines).map { |x| Gem::Version.new(x['version']) }.sort.reverse

      asdf_package_paths(current_asdf_data_dir, versions)
    end

    def asdf_package_paths(current_asdf_data_dir, versions)
      versions.each_with_object({}) do |version, paths|
        major_version, minor_version = version.canonical_segments[0..1]

        # We only care about the latest version
        next if paths.key?(major_version)

        paths[major_version] = "#{current_asdf_data_dir}/installs/postgres/#{major_version}.#{minor_version}/bin"
      end
    end

    def brew_cellar_available_versions
      POSTGRESQL_VERSIONS.each_with_object({}) do |version, paths|
        brew_cellar_pg = run(%W[brew --cellar postgresql@#{version}])

        next if brew_cellar_pg.empty?

        brew_cellar_pg_bin = Dir.glob(File.join(brew_cellar_pg, '/*/bin'))

        paths[version] = brew_cellar_pg_bin.last if brew_cellar_pg_bin.any?
      end
    end

    def apt_available_versions
      versions = POSTGRESQL_VERSIONS.map { |ver| "postgresql-#{ver}" }
      lines = run(%w[apt search -o APT::Cache::Search::Version=1 ^postgresql-[0-9]*$])

      return {} if lines.empty?

      available_packages = Set.new

      lines.split("\n").each do |line|
        package_data = line.strip.split
        available_packages << package_data.first.strip
      end

      postgresql_packages = available_packages & versions

      postgresql_packages.each_with_object({}) do |package, paths|
        version = package.gsub(/^postgresql-/, '').to_i
        pg_path = "/usr/lib/postgresql/#{version}/bin"
        paths[version] = pg_path if Dir.exist?(pg_path)
      end
    end

    def config
      @config ||= GDK.config
    end

    def run(cmd)
      Shellout.new(cmd).try_run
    end

    def run!(cmd, chdir)
      sh = Shellout.new(cmd, chdir: chdir)
      sh.try_run

      return true if sh.success?

      GDK::Output.puts(sh.read_stdout)
      GDK::Output.puts(sh.read_stderr)

      raise "'#{cmd}' failed."
    end

    def run_in_tmp!(cmd)
      run!(cmd, config.gdk_root.join('tmp'))
    end
  end
end
