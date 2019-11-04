# frozen_string_literal: true

require_relative './config'

module GDK
  class ConfigCommand
    class << self
      def exec(cmd, args)
        case cmd
        when 'get'
          self.get(args)
        when 'validate'
          self.validate
        else
          abort <<~CONFIG_COMMAND_USAGE
            Usage:
              gdk config get path.to.the.conf.value - get gdk config value
              gdk config validate - validate gdk config values
          CONFIG_COMMAND_USAGE
        end
      end

      def get(args)
        begin
          puts Config.new.dig(*args)
          true
        rescue GDK::ConfigSettings::SettingUndefined
          abort "Cannot get config for #{ARGV.join('.')}"
        end
      end

      def validate
        config = Config.new
        config.validate

        return true if config.error_messages.empty?

        abort "Invalid GDK configuration:\n#{config.error_messages.join("\n")}"
      end
    end
  end
end
