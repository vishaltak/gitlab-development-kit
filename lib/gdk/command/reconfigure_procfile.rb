# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure_procfile` command execution
    class ReconfigureProcfile < BaseCommand
      def run(_args = [])
        result = GDK.make('reconfigure_procfile')

        unless result
          GDK::Output.error('Failed to reconfigure Procfile.')
          display_help_message
        end

        result
      end
    end
  end
end
