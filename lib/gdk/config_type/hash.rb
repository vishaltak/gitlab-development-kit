# frozen_string_literal: true

require 'json'
require_relative 'base'
require_relative 'mergable'

module GDK
  module ConfigType
    class Hash < Base
      include Mergable

      class Instance < Base::Instance
        def parse
          value.is_a?(::Hash)
        end
      end

      private

      def do_merge(fetched, default)
        Hash(fetched).merge(default.transform_keys(&:to_s))
      end
    end
  end
end
