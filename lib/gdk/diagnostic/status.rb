# frozen_string_literal: true

module GDK
  module Diagnostic
    class Status < Base
      TITLE = 'GDK Status'

      def success?
        down_services.empty?
      end

      def detail
        return if success?

        <<~MESSAGE
          The following services are not running but should be:

          #{down_services.join("\n")}
        MESSAGE
      end

      private

      def gdk_status_command
        @gdk_status_command ||= Shellout.new('gdk status').execute(display_output: false, display_error: false)
      end

      def down_services
        @down_services ||= gdk_status_command.read_stdout.split("\n").select { |svc| svc.match?(/\Adown: .+, want up;.+\z/) }
      end
    end
  end
end
