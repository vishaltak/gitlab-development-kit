# frozen_string_literal: true

module GDK
  module Command
    class Kill < BaseCommand
      def run(_ = [])
        if runsv_processes_to_kill.empty?
          GDK::Output.info('No runsv processes detected.')
          return true
        end

        return true unless continue?

        if kill_runsv_processes!
          GDK::Output.success("All 'runsv' processes have been killed.")
          true
        else
          message = "Failed to kill all 'runsv' processes."
          message = "#{message} The following are still running:\n\n" unless runsv_processes_to_kill.empty?

          GDK::Output.error(message)
          GDK::Output.puts("#{runsv_processes_to_kill}\n\n") unless runsv_processes_to_kill.empty?
          false
        end
      end

      private

      def runsv_processes_to_kill
        Shellout.new('ps -ef | grep "[r]unsv"').try_run
      end

      def continue?
        GDK::Output.warn("You're about to kill the following runsv processes:\n\n")
        GDK::Output.puts("#{runsv_processes_to_kill}\n\n")

        return true if ENV.fetch('GDK_KILL_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

        GDK::Output.info("This command will stop all your GDK instances and any other process started by runit.\n\n")

        GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def kill_runsv_processes!
        gdk_stop_succeeded? || pkill_runsv_succeeded? || pkill_force_runsv_succeeded?
      end

      def gdk_stop_succeeded?
        GDK::Output.info("Running 'gdk stop' to be sure..")
        Runit.stop(quiet: true) && wait && runsv_processes_to_kill.empty?
      end

      def pkill_runsv_succeeded?
        pkill('runsv') && wait && runsv_processes_to_kill.empty?
      end

      def pkill_force_runsv_succeeded?
        pkill('-9 runsv') && wait && runsv_processes_to_kill.empty?
      end

      def pkill(args)
        command = "pkill #{args}"
        GDK::Output.info("Running '#{command}'..")
        sh = Shellout.new(command)
        sh.try_run

        # pkill returns 0 if one ore more processes were matched or 1 if no
        # processes were matched.
        [0, 1].include?(sh.exit_code)
      end

      def wait(length: 5)
        GDK::Output.info("Giving runsv processes #{length} seconds to die..")
        sleep(length)
      end
    end
  end
end
