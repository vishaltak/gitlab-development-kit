# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk update` command execution
    class Update < BaseCommand
      def run(_args = [])
        update_result = update!

        unless update_result
          GDK::Output.error('Failed to update.')
          display_help_message('Failed to update.')

          return false
        end

        return reconfigure! if config.gdk.auto_reconfigure?

        update_result
      end

      private

      def update!
        GDK::Hooks.with_hooks(config.gdk.update_hooks, 'gdk update') do
          GDK.make('self-update')
          GDK.make('self-update', 'update')
        end
      end

      def reconfigure!
        GDK.make('reconfigure-tasks')
      end
    end
  end
end
