# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Open < BaseCommand
      def run(_ = [])
        exec("#{open_command} '#{config.__uri}'")
      end

      private

      def open_command
        @open_command ||= config.__platform_linux? ? 'xdg-open' : 'open'
      end
    end
  end
end
