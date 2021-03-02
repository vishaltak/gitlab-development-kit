# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk config` command execution
    #
    # This command accepts the following subcommands:
    # - get <config keys separated by space>
    class Config
      def run(args)
        config_command = args.shift
        GDK::Output.abort('Usage: gdk config get <configuration value>') if config_command != 'get' || args.empty?

        begin
          puts GDK.config.dig(*args)
          true
        rescue GDK::ConfigSettings::SettingUndefined
          GDK::Output.abort("Cannot get config for #{args.join('.')}")
          false
        end
      end
    end
  end
end
