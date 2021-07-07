# frozen_string_literal: true

require_relative 'base'
require_relative 'mergable'

module GDK
  module ConfigType
    class Array < Base
      include Mergable

      def parse(value)
        value.to_a
      end

      private

      def mergable_merge(fetched, default)
        default + Array(fetched)
      end
    end
  end
end
