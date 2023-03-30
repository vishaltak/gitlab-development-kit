# frozen_string_literal: true

require 'thread'

module GDK
  module Dependencies
    class Checker
      EXPECTED_GO_VERSION = '1.15'
      EXPECTED_YARN_VERSION = '1.22.5'
      EXPECTED_NODEJS_VERSION = '12.18.3'
      EXPECTED_POSTGRESQL_VERSION = GDK::Postgresql.target_version.to_s

      attr_reader :error_messages

      def self.parse_version(string, prefix: '')
        string[/#{prefix}((\d+\.\d+)(\.\d+)*)/, 1]
      end

      def initialize
        @error_messages = []
      end

      def check_all
        jobs = [
          Thread.new { check_ruby_version },
          Thread.new { check_go_version },
          Thread.new { check_nodejs_version },
          Thread.new { check_yarn_version },
          Thread.new { check_postgresql_version },
          Thread.new { check_git_installed },
          Thread.new { check_graphicsmagick_installed },
          Thread.new { check_exiftool_installed },
          Thread.new { check_minio_installed },
          Thread.new { check_runit_installed },
        ]

        jobs.each(&:join)
      end

      def check_binary(binary, name: binary)
        GDK::Dependencies.find_executable(binary).tap do |result|
          @error_messages << missing_dependency(name) unless result
        end
      end

      def check_ruby_version
        return unless check_binary('ruby')

        cmd = 'ruby --version'
        # .tool-versions may have changed during a `gdk update`, so we
        # should execute ruby using asdf to avoid a stale PATH.
        cmd = "asdf exec #{cmd}" if GDK.config.asdf.__available?

        raw_version_match = Shellout.new(cmd).try_run.match(/\Aruby (.+)p\d+ \(.+\z/)
        return unless raw_version_match

        actual = Gem::Version.new(raw_version_match[1])
        expected = Gem::Version.new(GitlabVersions.new.ruby_version)

        @error_messages << require_minimum_version('Ruby', actual, expected) if actual < expected
      end

      def check_go_version
        return unless check_binary('go')

        current_version = Checker.parse_version(`go version`, prefix: 'go')
        expected = Gem::Version.new(EXPECTED_GO_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('Go', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('Go', minimum_version: EXPECTED_GO_VERSION)
      end

      def check_nodejs_version
        return unless check_binary('node')

        current_version = Checker.parse_version(`node --version`, prefix: 'v')

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_NODEJS_VERSION)

        @error_messages << require_minimum_version('Node.js', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('Node.js', minimum_version: EXPECTED_NODEJS_VERSION)
      end

      def check_yarn_version
        return unless check_binary('yarn')

        current_version = Checker.parse_version(`yarn --version`)
        expected = Gem::Version.new(EXPECTED_YARN_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('Yarn', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('Yarn', minimum_version: expected)
      end

      def check_postgresql_version
        return unless check_binary('psql')

        current_version = Checker.parse_version(`psql --version`, prefix: 'psql \(PostgreSQL\) ')
        expected = Gem::Version.new(EXPECTED_POSTGRESQL_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('PostgreSQL', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('PostgreSQL', minimum_version: expected)
      end

      def check_git_installed
        check_binary('git')
      end

      def check_graphicsmagick_installed
        @error_messages << missing_dependency('GraphicsMagick') unless system("gm version >/dev/null 2>&1")
      end

      def check_exiftool_installed
        return if system("exiftool -ver >/dev/null 2>&1")

        msg = "You may need to run 'brew reinstall exiftool'." if GDK::Machine.macos?
        @error_messages << missing_dependency('Exiftool', more_detail: msg)
      end

      def check_minio_installed
        return unless config.object_store.enabled?

        @error_messages << missing_dependency('MinIO') unless system('minio --help >/dev/null 2>&1')
      end

      def check_runit_installed
        check_binary('runsvdir', name: 'Runit')
      end

      def require_minimum_version(dependency, actual, expected)
        "ERROR: #{dependency} version #{actual} detected, please install #{dependency} version #{expected} or higher."
      end

      def missing_dependency(dependency, minimum_version: nil, more_detail: nil)
        message = "ERROR: #{dependency} is not installed or not available in your PATH."
        message += " #{minimum_version} or higher is required." unless minimum_version.nil?
        message += " #{more_detail}" unless more_detail.nil?

        message
      end

      private

      def config
        @config ||= GDK.config
      end
    end
  end
end
