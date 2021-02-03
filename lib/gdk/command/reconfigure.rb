# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Reconfigure
      def run
        GDK.remember!(GDK.root)

        result = GDK.make('reconfigure')

        unless result
          GDK::Output.error('Failed to reconfigure.')
          GDK.display_help_message
        end

        result
      end
    end
  end
end
