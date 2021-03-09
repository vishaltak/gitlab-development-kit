# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk update` command execution
    class Update
      def run
        update_result = update!

        unless update_result
          GDK::Output.error('Failed to update.')
          GDK.display_help_message

          return false
        end

        return reconfigure! if GDK.config.gdk.auto_reconfigure?

        update_result
      end

      private

      def update!
        GDK.with_hooks(GDK.config.gdk.update_hooks, 'gdk update') do
          GDK.make('self-update')
          GDK.make('self-update', 'update')
        end
      end

      def reconfigure!
        GDK::Command::Reconfigure.new.run
      end
    end
  end
end
