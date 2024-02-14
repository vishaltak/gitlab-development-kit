# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk update` command execution
    class Update < BaseCommand
      def run(_args = [])
        update_result = update!

        unless update_result
          GDK::Output.error('Failed to update.')
          display_help_message

          return false
        end

        return reconfigure! if config.gdk.auto_reconfigure?

        update_result
      end

      private

      def update!
        GDK::Hooks.with_hooks(config.gdk.update_hooks, 'gdk update') do
          # Run `self-update` first to make sure Makefiles are up-to-date.
          # This ensures the next `make update` call works with the latest updates and instructions.
          GDK.make('self-update') if self_update?

          GDK.make('update', env: update_env).success?
        end
      end

      def reconfigure!
        GDK.make('reconfigure-tasks').success?
      end

      def self_update?
        %w[1 yes true].include?(ENV.fetch('GDK_SELF_UPDATE', '1'))
      end

      def update_env
        { 'PG_AUTO_UPDATE' => '1' }
      end
    end
  end
end
