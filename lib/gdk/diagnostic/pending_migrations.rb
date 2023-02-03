# frozen_string_literal: true

module GDK
  module Diagnostic
    class PendingMigrations < Base
      TITLE = 'Database Migrations'

      def success?
        db_migrations_shellout.execute(display_output: false, display_error: false).success?
      end

      def detail
        return if success?

        <<~MESSAGE
          There are pending database migrations.  To update your database, run:

            (gdk start db && cd #{config.gitlab.dir} && #{config.gdk_root}/support/bundle-exec rails db:migrate)
        MESSAGE
      end

      private

      def db_migrations_shellout
        @db_migrations_shellout ||= Shellout.new(%W[#{config.gdk_root}/support/bundle-exec rails db:abort_if_pending_migrations], chdir: config.gitlab.dir.to_s)
      end
    end
  end
end
