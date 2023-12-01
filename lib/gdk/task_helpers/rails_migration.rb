# frozen_string_literal: true

require 'forwardable'

module GDK
  module TaskHelpers
    # Class to work with database migrations on gitlab-rails
    class RailsMigration
      extend Forwardable

      MAIN_TASKS = %w[db:migrate db:test:prepare].freeze
      GEO_TASKS = %w[db:migrate:geo db:test:prepare:geo].freeze

      def_delegators :postgresql, :in_recovery?

      def migrate
        tasks = migrate_tasks

        return if migrate_tasks.empty?

        display_migrate_message(tasks.keys)
        rake(tasks.values.flatten)
      end

      private

      def migrate_tasks
        tasks = {}
        tasks['rails'] = MAIN_TASKS unless geo_secondary? || in_recovery?
        tasks['Geo'] = GEO_TASKS if geo_secondary?

        tasks
      end

      def display_migrate_message(tasks)
        str = tasks.join(' and ')

        GDK::Output.divider
        GDK::Output.puts("Processing gitlab #{str} DB migrations")
        GDK::Output.divider
      end

      def rake(tasks)
        GDK::Execute::Rake.new(*tasks).execute_in_gitlab.success?
      end

      def geo_secondary?
        GDK.config.geo.secondary?
      end

      def geo?
        GDK.config.geo?
      end

      def postgresql
        @postgresql ||= GDK::Postgresql.new
      end
    end
  end
end
