# frozen_string_literal: true

module GDK
  module ConfigType
    class Base
      class Instance
        attr_reader :key, :parent
        attr_accessor :value

        def initialize(value, key:, parent:)
          @value = value
          @key = key
          @parent = parent

          validate!
        end

        def validate!
          orig_value = value

          return if parse

          raise ::TypeError, "Value '#{orig_value}' for #{slug} is not a valid #{type}"
        end

        def dump!
          value
        end

        def slug
          [parent.slug, key].compact.join('.')
        end

        def root
          parent&.root || self
        end
        alias_method :config, :root

        private

        def type
          self.class.name.split('::').last(2).first.downcase
        end
      end

      attr_reader :key, :blk

      def initialize(key:, &blk)
        @key = key
        @blk = blk
      end

      def ignore?
        key.start_with?('__') || key.end_with?('?')
      end

      def instanciate(parent:)
        value = parent.yaml.fetch(key, parent.instance_eval(&blk))

        self.class::Instance.new(value, key: key, parent: parent)
      end
    end
  end
end
