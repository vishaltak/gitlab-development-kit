# frozen_string_literal: true

require_relative '../../gdk'

module GDK
  module Command
    # Truncate legacy database tables to remove stale data in the CI decomposed database
    class TruncateLegacyTables < BaseCommand
      FLAG_FILE = "#{GDK.root}/.cache/.truncate_tables".freeze

      def run(_args = [])
        unless truncation_needed?
          GDK::Output.info('Truncation not required as your GDK is up-to-date.')
          return true
        end

        ensure_databases_running
        truncate_tables
        true
      end

      def truncation_needed?
        ci_database_enabled? && !geo_secondary? && !flag_file_exists?
      end

      private

      def ci_database_enabled?
        GDK.config.gitlab.rails.databases.ci.enabled
      end

      def geo_secondary?
        GDK.config.geo.secondary?
      end

      def flag_file_exists?
        File.exist?(FLAG_FILE)
      end

      def ensure_databases_running
        GDK::Command::Start.new.run(['rails-migration-dependencies'])
      end

      def truncate_tables
        GDK::Output.notice('Ensuring legacy data in main & ci databases are truncated.')

        if execute_truncation_tasks
          report_success
          create_flag_file
        else
          report_failure
        end
      end

      def execute_truncation_tasks
        rake_tasks = %w[
          gitlab:db:lock_writes
          gitlab:db:truncate_legacy_tables:main
          gitlab:db:truncate_legacy_tables:ci
          gitlab:db:unlock_writes
        ].freeze

        GDK::Execute::Rake.new(*rake_tasks).execute_in_gitlab.success?
      end

      def report_success
        GDK::Output.success('Legacy table truncation completed successfully.')
      end

      def create_flag_file
        FileUtils.mkdir_p(File.dirname(FLAG_FILE))
        FileUtils.touch(FLAG_FILE)
      end

      def report_failure
        GDK::Output.error('Legacy table truncation failed.')
      end
    end
  end
end
