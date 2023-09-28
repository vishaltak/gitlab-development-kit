# frozen_string_literal: true

module GDK
  module Dependencies
    module PostgreSQL
      # PostgreSQL Binaries refer to the installation dependency
      # containing the client and server binaries required to run the database
      #
      # This is mostly used by the Upgrader, which requires access to multiple versions
      # to orchestrate an upgrade without user intervention
      class Binaries
        POSTGRESQL_VERSIONS = %w[14 13 12 11 10 9.6].freeze

        attr_reader :version

        def initialize(version:)
          @version = version

          validate!
        end

        def validate!
          if available_versions.empty?
            GDK::Output.error 'Only Homebrew, asdf and apt based Linux systems supported.'

            exit 1
          end

          unless bin_path
            GDK::Output.error "Invalid PostgreSQL version #{version}"

            exit 1
          end

          true
        end

        def initdb_bin
          File.join(bin_path, 'initdb')
        end

        def pg_upgrade_bin
          File.join(bin_path, 'pg_upgrade')
        end

        def bin_path
          available_versions[version]
        end

        def available_versions
          @available_versions ||=
            if GDK::Dependencies.asdf_available?
              asdf_available_versions
            elsif GDK::Dependencies.homebrew_available?
              brew_cellar_available_versions.transform_keys(&:to_i)
            elsif GDK::Dependencies.linux_apt_available?
              apt_available_versions
            end
        end

        def asdf_available_versions
          lines = run(%w[asdf list postgres])
          return {} if lines.empty?

          current_asdf_data_dir = ENV.fetch('ASDF_DATA_DIR', "#{Dir.home}/.asdf")

          versions = lines.split.map { |x| Gem::Version.new(x) }.sort.reverse
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

        private

        def run(cmd)
          Shellout.new(cmd).try_run
        end
      end
    end
  end
end
