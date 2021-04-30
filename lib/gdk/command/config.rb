# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk config` command execution
    #
    # This command accepts the following subcommands:
    # - get <config key>
    # - set <config key> <value>
    class Config < BaseCommand
      def run(args = [])
        config_command = args.shift
        if config_command == 'get' && args.length == 1
          config_get(*args)
        elsif config_command == 'set' && args.length == 2
          config_set(*args)
        else
          GDK::Output.warn('Usage: gdk config [<get>|set] <name> [<value>]')
          abort
        end
      end

      private

      def config
        @config ||= GDK.config
      end

      def config_get(*name)
        puts config.dig(*name)
        true
      rescue GDK::ConfigSettings::SettingUndefined
        GDK::Output.abort("Cannot get config for #{name.join('.')}")
      end

      def config_set(name, new_value)
        current_value = config.dig(*name)
        config.bury(name, new_value)
        GDK::Output.info("'#{name}' is now set to '#{new_value}' (previously '#{current_value}').")

        true
      rescue GDK::ConfigSettings::SettingValueIsUnchanged
        GDK::Output.info("'#{name}' is already set to '#{new_value}'.")

        true
      rescue GDK::ConfigSettings::SettingIsASettingsBlock
        GDK::Output.abort("'#{name}' cannot be updated because it's a settings block.")
      rescue GDK::ConfigSettings::SettingUndefined
        GDK::Output.abort("Cannot get config for '#{name}'.")
      rescue GDK::ConfigSettings::SettingValueInvalid
        GDK::Output.abort("'#{new_value}' is a invalid value for '#{name}'.")
      rescue TypeError => e
        GDK::Output.abort(e.message)
      rescue StandardError => e
        GDK::Output.error(e.message)
        abort
      end
    end
  end
end
