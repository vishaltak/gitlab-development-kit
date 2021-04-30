# frozen_string_literal: true

require 'json'
require_relative 'base'
require_relative 'mergable'

module GDK
  module ConfigType
    class Hash < Base
      include Mergable

      def self.cast_value(value)
        Hash(value)
      rescue TypeError
        raise TypeError, "'#{value}' does not appear to be a valid Hash."
      end

      def self.parse(value)
        value.is_a?(::Hash)
      end

      def parse
        self.class.parse(value)
      end

      private

      def mergable_merge(fetched, default)
        Hash(fetched).merge(default.transform_keys(&:to_s))
      end
    end
  end
end
