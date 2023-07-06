# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk config` command execution
    #
    # This command accepts the following subcommands:
    # - list
    # - get <config key>
    # - set <config key> <value>
    class Config < BaseCommand
      def run(args = [])
        case args.shift
        when 'get'
          config_get(*args)
        when 'set'
          GDK::Output.abort('Usage: gdk config set <name> <value>') if args.length != 2

          config_set(*args)
        when 'list'
          GDK::Output.puts(config)
          true
        else
          GDK::Output.warn('Usage: gdk config [<get>|set] <name> [<value>]')
          GDK::Output.warn('       gdk config list')
          abort
        end
      end

      private

      def config
        @config ||= GDK.config
      end

      def config_get(*name)
        GDK::Output.abort('Usage: gdk config get <name>') if name.empty?

        GDK::Output.puts(config.dig(*name))

        true
      rescue GDK::ConfigSettings::SettingUndefined
        GDK::Output.abort("Cannot get config for #{name.join('.')}")
      rescue GDK::ConfigSettings::UnsupportedConfiguration => e
        GDK::Output.abort("#{e.message}.")
      end

      def config_set(slug, value)
        value_stored_in_gdk_yml = config.user_defined?(*slug)
        old_value = config.dig(*slug)
        new_value = config.bury!(slug, value)

        if old_value == new_value && value_stored_in_gdk_yml
          GDK::Output.warn("'#{slug}' is already set to '#{old_value}'")
          return true
        elsif old_value == new_value && !value_stored_in_gdk_yml
          GDK::Output.success("'#{slug}' is now set to '#{new_value}' (explicitly setting '#{old_value}').")
        elsif old_value != new_value && value_stored_in_gdk_yml
          GDK::Output.success("'#{slug}' is now set to '#{new_value}' (previously '#{old_value}').")
        else
          GDK::Output.success("'#{slug}' is now set to '#{new_value}' (previously using default '#{old_value}').")
        end

        config.save_yaml!
        GDK::Output.info("Don't forget to run 'gdk reconfigure'.")

        true
      rescue GDK::ConfigSettings::SettingUndefined
        GDK::Output.abort("Cannot get config for '#{slug}'.")
      rescue TypeError => e
        GDK::Output.abort(e.message)
      rescue StandardError => e
        GDK::Output.error(e.message)
        abort
      end
    end
  end
end
