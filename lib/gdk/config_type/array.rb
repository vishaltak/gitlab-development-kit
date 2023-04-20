# frozen_string_literal: true

module GDK
  module ConfigType
    class Array < Base
      include Mergable

      def parse(value)
        if value.is_a?(::String)
          value.split(',').map(&:strip)
        else
          value.to_a
        end
      end

      private

      def mergable_merge(fetched, default)
        default + Array(fetched)
      end
    end
  end
end
