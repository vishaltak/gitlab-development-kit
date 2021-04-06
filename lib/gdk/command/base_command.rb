# frozen_string_literal: true

module GDK
  module Command
    # Base interface for GDK commands
    class BaseCommand
      attr_reader :stdout, :stderr

      def initialize(stdout: $stdout, stderr: $stderr)
        @stdout = stdout
        @stderr = stderr
      end

      def run(args = [])
        raise NotImplementedError
      end
    end
  end
end
