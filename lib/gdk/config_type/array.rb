# frozen_string_literal: true

require_relative 'base'
require_relative 'mergable'

module GDK
  module ConfigType
    class Array < Base
      include Mergable

      class Instance < Base::Instance
        def parse
          value.is_a?(::Array)
        end
      end

      private

      def do_merge(fetched, default)
        default + Array(fetched)
      end
    end
  end
end
