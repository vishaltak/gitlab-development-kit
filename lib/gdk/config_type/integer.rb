# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Integer < Base
      def self.cast_value(value)
        Integer(value)
      rescue TypeError, ArgumentError
        raise TypeError, "'#{value}' does not appear to be a valid Integer."
      end

      def parse
        orig_value = value
        self.value = self.class.cast_value(value)

        value.to_s == orig_value.to_s
      rescue TypeError, NoMethodError
        false
      end
    end
  end
end
