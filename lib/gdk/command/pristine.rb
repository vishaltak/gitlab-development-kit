# frozen_string_literal: true

module GDK
  module Command
    class Pristine
      def run
        command.stream
      end

      private

      def command
        @command ||= Shellout.new(%w[make pristine])
      end
    end
  end
end
