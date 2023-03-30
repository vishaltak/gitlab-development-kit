# frozen_string_literal: true

module GDK
  module Diagnostic
    class PendingMigrations < Base
      TITLE = 'Database Migrations'

      def success?
        return @success if defined?(@success)

        @success ||= begin
          # If there's bundler issues, this will result in a false negative
          # so let's just return true here for now.
          return true unless Diagnostic::RubyGems.new.gitlab_bundle_check_ok?

          db_migrations_shellout.execute(display_output: false, display_error: false).success?
        end
      end

      def detail
        return if success?

        <<~MESSAGE
          There are pending database migrations.  To update your database, run:

            (gdk start db && cd #{config.gitlab.dir} && #{bundle_exec_cmd} rails db:migrate)
        MESSAGE
      end

      private

      def db_migrations_shellout
        @db_migrations_shellout ||= Shellout.new(%W[#{bundle_exec_cmd} rails db:abort_if_pending_migrations], chdir: config.gitlab.dir.to_s)
      end
    end
  end
end
