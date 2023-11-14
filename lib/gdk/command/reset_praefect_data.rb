# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reset-praefect-data` command execution
    class ResetPraefectData < BaseCommand
      def run(_ = [])
        return false unless continue?

        execute
      end

      private

      def continue?
        GDK::Output.warn("We're about to remove Praefect PostgreSQL data.")

        return true if ENV.fetch('GDK_RESET_PRAEFECT_DATA_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

        GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def execute
        Runit.stop(quiet: true) &&
          # ensure runit has fully stopped
          sleep(2) &&
          start_necessary_services &&
          # ensure runit has fully stopped
          sleep(2) &&
          drop_database &&
          recreate_database &&
          migrate_database
      end

      def start_necessary_services
        Runit.start('postgresql', quiet: true)
      end

      def psql_cmd(command)
        GDK::Postgresql.new.psql_cmd(['-c'] + [command])
      end

      def drop_database
        shellout(psql_cmd('drop database praefect_development'))
      end

      def recreate_database
        shellout(psql_cmd('create database praefect_development'))
      end

      def migrate_database
        shellout(GDK.root.join('support', 'migrate-praefect').to_s)
      end

      def shellout(command)
        sh = Shellout.new(command, chdir: GDK.root)
        sh.stream
        sh.success?
      end
    end
  end
end
