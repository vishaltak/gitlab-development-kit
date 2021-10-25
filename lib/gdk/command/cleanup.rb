# frozen_string_literal: true

require 'rake'

module GDK
  module Command
    class Cleanup < BaseCommand
      def run(_ = [])
        return true unless continue?

        execute
      end

      private

      def continue?
        GDK::Output.warn("About to perform the following actions:")
        GDK::Output.puts(stderr: true)
        GDK::Output.puts('- Truncate gitlab/log/* files', stderr: true)
        GDK::Output.puts('- Uninstall any asdf software that is not defined in .tool-versions', stderr: true) if unnecessary_software_to_uninstall?
        GDK::Output.puts(stderr: true)

        return true if ENV.fetch('GDK_CLEANUP_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

        result = GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
        GDK::Output.puts(stderr: true)

        result
      end

      def execute
        truncate_log_files
        uninstall_unnecessary_software
      rescue StandardError => e
        GDK::Output.error(e)
        false
      end

      def truncate_log_files
        execute_rake_task('gitlab:truncate_logs', 'gitlab.rake', args: 'false')
      end

      def unnecessary_software_to_uninstall?
        @unnecessary_software_to_uninstall ||= Asdf::ToolVersions.new.unnecessary_software_to_uninstall?
      end

      def uninstall_unnecessary_software
        return true unless unnecessary_software_to_uninstall?

        execute_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake', args: 'false')
      end

      def execute_rake_task(task_name, rake_file, args: nil)
        Kernel.load(GDK.root.join('lib', 'tasks', rake_file))

        Rake::Task[task_name].invoke(args)
        true
      rescue RuntimeError => e
        GDK::Output.error(e)
        false
      end
    end
  end
end
