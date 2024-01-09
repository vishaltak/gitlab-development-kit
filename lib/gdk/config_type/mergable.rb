# frozen_string_literal: true

module GDK
  module ConfigType
    module Mergable
      attr_reader :merge

      def initialize(parent:, builder:, merge: false)
        @merge = merge

        super(parent:, builder:)
      end

      def read_value
        val = super

        return val if !merge || !user_defined?

        mergable_merge(user_value, default_value)
      end
    end
  end
end
