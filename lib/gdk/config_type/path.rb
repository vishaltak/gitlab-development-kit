# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module GDK
  module ConfigType
    class Path < Base
      def self.cast_value(value)
        if !%w[String Pathname].include?(value.class.to_s) ||
            ConfigType::Bool.value_matches_type?(value) ||
            ConfigType::Integer.value_matches_type?(value)
          raise TypeError, "'#{value}' does not appear to be a valid Path."
        end

        value.to_s
      end

      def self.value_valid?(value)
        super && File.exist?(value)
      rescue TypeError
        false
      end

      def dump!(user_only: false)
        value.to_s
      end

      def parse
        return unless self.class.cast_value(value)

        self.value = Pathname.new(value)

        true
      rescue TypeError
        false
      end
    end
  end
end
