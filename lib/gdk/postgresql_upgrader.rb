# frozen_string_literal: true

require 'fileutils'
require 'forwardable'
require 'json'
require 'set'

require_relative 'postgresql'

module GDK
  # PostgreSQL Upgrader coordinates the upgrade of existing PostgreSQL installation
  #
  # The upgrade can use any of the supported dependency mechanisms, and doesn't require
  # to use the same as the existing one. As long as the current and target version can be found
  # the upgrade process will be executed
  class PostgresqlUpgrader
    extend Forwardable

    def_delegators :postgresql, :current_data_dir, :current_version, :upgrade_needed?

    attr_reader :current_pg, :new_pg

    def initialize(running_version: current_version, target_version: GDK::Postgresql.target_version_major)
      @target_version = target_version
      @current_pg = GDK::Dependencies::PostgreSQL::Binaries.new(version: running_version)
      @new_pg = GDK::Dependencies::PostgreSQL::Binaries.new(version: target_version)
    end

    def check!
      GDK::Output.info "Available PostgreSQL versions: #{available_versions}"

      GDK::Output.abort "Unable to find target PostgreSQL version #{target_version}" unless available_versions.include?(target_version)
      GDK::Output.abort "Unable to find current PostgreSQL version #{current_version}" unless available_versions.include?(current_version)
    end

    def upgrade!
      check!

      unless upgrade_needed?(target_version)
        GDK::Output.success "'#{current_data_dir}' is already compatible with PostgreSQL #{target_version}."

        return true
      end

      begin
        run_gdk!('stop')
        init_db_in_target_path
        pgvector_setup
        rename_current_data_dir
        pg_upgrade
        promote_new_db
        run_gdk!('reconfigure')
        pg_replica_upgrade('replica')
        pg_replica_upgrade('replica_2')
      rescue StandardError => e
        GDK::Output.error("An error occurred: #{e}", e)
        GDK::Output.warn 'Rolling back..'
        rename_current_data_dir_back
        GDK::Output.warn "Upgrade failed. Rolled back to the original PostgreSQL #{current_version}."

        return false
      end

      GDK::Output.success "Upgraded '#{current_data_dir}' from PostgreSQL #{current_version} to #{target_version}."

      true
    end

    private

    attr_reader :target_version

    def postgresql
      @postgresql ||= GDK::Postgresql.new
    end

    def renamed_current_data_dir
      @renamed_current_data_dir ||= "#{current_data_dir}.#{current_version}.#{Time.now.to_i}"
    end

    def target_path
      @target_path ||= "#{current_data_dir}.#{target_version}.#{Time.now.to_i}"
    end

    def init_db_in_target_path
      GDK::Output.info "Initializing '#{target_path}' for PostgreSQL #{target_version}.."

      cmd = "#{new_pg.initdb_bin} --locale=C -E utf-8 #{target_path}"
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
      return unless GDK.config.gitlab.rails.databases.embedding.enabled?

      GDK::Output.info "Running 'make pgvector-clean pgvector-setup'.."

      run!('make pgvector-clean pgvector-setup', GDK.config.gdk_root)
    end

    def pg_upgrade
      cmd = "#{new_pg.pg_upgrade_bin} \
      --old-bindir #{current_pg.bin_path} \
      --new-bindir #{new_pg.bin_path} \
      --old-datadir #{renamed_current_data_dir} \
      --new-datadir #{target_path}"

      GDK::Output.info "Upgrading '#{renamed_current_data_dir}' (PostgreSQL #{current_version}) to '#{target_path}' PostgreSQL #{target_version}.."

      run_in_tmp!(cmd)
    end

    def remove_secondary_data?(replica_name)
      return false unless GDK.config.postgresql.public_send(replica_name).enabled? # rubocop:disable GitlabSecurity/PublicSend

      GDK::Output.warn("We're about to remove the old '#{replica_name}' database data because we will be replacing it with the primary database data.")

      return true if ENV.fetch('PG_AUTO_UPDATE', 'false') == 'true' || !GDK::Output.interactive?

      GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
    end

    def pg_replica_upgrade(replica_name)
      return true unless remove_secondary_data?(replica_name)

      pg_primary_dir = GDK.config.gdk_root.join('postgresql')
      pg_secondary_data_dir = GDK.config.gdk_root.join("postgresql-#{replica_name.tr('_', '-')}/data")

      GDK::Output.info 'Removing the old secondary database data...'
      run!("rm -rf #{pg_secondary_data_dir}", config.gdk_root)

      replication_user = GDK.config.postgresql.replication_user

      GDK::Output.info 'Copying data from primary to secondary...'
      cmd = "pg_basebackup -R -h #{pg_primary_dir} -D #{pg_secondary_data_dir} -P -U #{replication_user} --wal-method=fetch"
      run!(cmd, GDK.config.gdk_root)
    end

    def promote_new_db
      GDK::Output.info "Promoting newly-creating database from '#{target_path}' to '#{current_data_dir}'"

      FileUtils.mv(target_path, current_data_dir)
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
      run!(cmd, GDK.config.gdk_root.join('tmp'))
    end

    # Run GDK cli with provider args
    #
    # @param [Array<String>] args
    def run_gdk!(*args)
      GDK::Output.info "Running 'gdk #{cmd.join(' ')}'.."

      cmd = ['gdk'] + args
      run!(cmd, GDK.config.gdk_root)
    end
  end
end
