# frozen_string_literal: true

module GDK
  module ConfigType
    module Mergable
      attr_reader :merge

      def initialize(key:, merge: false, &blk)
        super(key: key, &blk)

        @merge = merge
      end

      def instanciate(parent:)
        default = parent.instance_eval(&blk)

        value = if merge
                  do_merge(parent.yaml.fetch(key, nil), default)
                else
                  parent.yaml.fetch(key, default)
                end

        self.class::Instance.new(value, key: key, parent: parent)
      end
    end
  end
end
