require 'open3'

module GDK
  module Command
    UndefinedCommandError = Class.new(StandardError)
    CommandFailureError = Class.new(StandardError)

    class BaseCommand
      attr_reader :cmd, :recover_cmd, :description

      def invoke
        timed_execution(description) do
          begin
            try_execute
          rescue CommandFailureError => e
            try_recover(e)
            try_execute
          end
        end
      end

      def working_directory
        config.gdk_root
      end

      private

      def try_execute
        run_cmd(cmd)
      end

      # Recover can have a non-zero execute and still clean up. If the recover
      # command is defined, execute it, and retry the original command
      def try_recover(error)
        raise error unless defined?(recover_cmd)
        raise error unless recover_cmd.count > 0

        begin
          run_cmd(recover_cmd)
        rescue CommandFailureError
        end
      end

      def run_cmd(command)
        validate_command!(command)

        Open3.popen2e(*command, chdir: working_directory) do |_stdin, out, wait_thread|
          unless wait_thread.value.success?
            message = out.readlines.join('\n')

            raise CommandFailureError, "Command #{command.join(" ")}: #{message}"
          end
        end
      end

      def timed_execution(description)
        puts "==> #{description}"
        start = Time.now

        yield
      ensure
        puts "    Finished in #{Time.now - start} seconds...\n"
      end

      def validate_command!(command)
        raise "Command must be an Array" unless command.is_a?(Array)
        raise UndefinedCommandError, "command was undefined" if command.count == 0
      end

      def config
        @config ||= GDK::Config.new
      end
    end
  end
end
