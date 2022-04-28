# frozen_string_literal: true

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
