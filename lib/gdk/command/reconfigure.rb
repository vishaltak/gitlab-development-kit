# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Reconfigure < BaseCommand
      def run(_args = [])
        result = GDK.make('reconfigure')

        unless result.success?
          GDK::Output.error('Failed to reconfigure.', result.stderr_str)
          display_help_message
        end

        result.success?
      end
    end
  end
end
