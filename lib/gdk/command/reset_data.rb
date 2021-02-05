# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reset-data` command execution
    class ResetData
      def run
        reset_data
      end

      private

      def reset_data
        GDK.remember!(GDK.root)
        Runit.stop

        path = GDK.root.join('./support/backup-data')
        sh = Shellout.new(path.to_s, chdir: GDK.root)
        sh.run

        unless sh.success?
          GDK::Output.error('Failed to backup data.')
          GDK.display_help_message
          return
        end

        make_result = GDK.make

        GDK::Output.puts

        if make_result
          GDK::Output.notice('Successfully reset data!')
          GDK.start([])
        else
          GDK::Output.error('Failed to reset data.')
          GDK.display_help_message
        end

        GDK::Output.puts

        make_result
      end
    end
  end
end
