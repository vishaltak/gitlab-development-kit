# frozen_string_literal: true

require 'forwardable'
require 'benchmark'

module GDK
  module TaskHelpers
    # Class to work with database migrations on gitlab-rails
    class RailsMigration
      extend Forwardable

      MAIN_TASKS = %w[db:migrate db:test:prepare].freeze
      GEO_TASKS = %w[db:migrate:geo db:test:prepare:geo].freeze
      MIGRATION_TIMEOUT = 600

      def_delegators :config, :geo?
      def_delegators :postgresql, :in_recovery?

      def migrate
        tasks = migrate_tasks

        return if migrate_tasks.empty?

        display_migrate_message(tasks.keys)

        begin
          Timeout.timeout(MIGRATION_TIMEOUT) do
            timings = Benchmark.measure do
              rake(tasks.values.flatten)
            end
            GDK::Output.notice("Migration finished. Timings:\n#{Benchmark::CAPTION} #{timings}")
          end
        rescue Timeout::Error
          GDK::Output.error('Migration took longer than 10 minutes and was terminated.')
          exit(1)
        end
      end

      private

      def migrate_tasks
        tasks = {}
        tasks['rails'] = MAIN_TASKS unless geo_secondary? || in_recovery?
        tasks['Geo'] = GEO_TASKS if geo?

        tasks
      end

      def display_migrate_message(tasks)
        str = tasks.join(' and ')

        GDK::Output.divider
        GDK::Output.puts("Processing gitlab #{str} DB migrations")
        GDK::Output.divider
      end

      def rake(tasks)
        cmd = %w[bundle exec rake] + tasks
        cmd = %w[asdf exec] + cmd if config.asdf.__available?

        Shellout.new(cmd, chdir: config.gitlab.dir).execute.success?
      end

      def geo_secondary?
        config.geo.secondary?
      end

      def config
        @config ||= GDK.config
      end

      def postgresql
        @postgresql ||= GDK::Postgresql.new
      end
    end
  end
end
