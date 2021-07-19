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
        case args.shift
        when 'get'
          config_get(*args)
        when 'set'
          GDK::Output.abort('Usage: gdk config set <name> <value>') if args.length != 2

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
        GDK::Output.abort('Usage: gdk config get <name>') if name.empty?

        GDK::Output.puts(config.dig(*name))

        true
      rescue GDK::ConfigSettings::SettingUndefined
        GDK::Output.abort("Cannot get config for #{name.join('.')}")
      rescue GDK::ConfigSettings::UnsupportedConfiguration => e
        GDK::Output.abort("#{e.message}.")
      end

      def config_set(slug, proposed_new_value)
        old_value = config.dig(*slug)

        if config.values_same_for_slug?(slug, proposed_new_value)
          GDK::Output.warn("'#{slug}' is already set to '#{proposed_new_value}'")
        else
          new_value = config.bury!(slug, proposed_new_value)
          GDK::Output.success("'#{slug}' is now set to '#{new_value}' (previously '#{old_value}').")
          GDK::Output.info("Don't forget to run 'gdk reconfigure'")
        end

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
