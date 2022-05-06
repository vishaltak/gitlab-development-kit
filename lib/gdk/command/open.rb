# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Open < BaseCommand
      def run(_ = [])
        if test_url.check_url_oneshot
          open_exec
          return true
        end

        unless test_url.wait(verbose: false)
          GDK::Output.error('GDK is not up. Please run `gdk start` and try again.')
          return false
        end

        open_exec
        true
      rescue Interrupt
        # CTRL-C was pressed
        true
      end

      private

      def test_url
        @test_url ||= GDK::TestURL.new
      end

      def open_exec
        exec("#{open_command} '#{config.__uri}'")
      end

      def open_command
        @open_command ||= config.__platform_linux? ? 'xdg-open' : 'open'
      end
    end
  end
end
