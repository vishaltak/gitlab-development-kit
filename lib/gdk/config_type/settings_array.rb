# frozen_string_literal: true

module GDK
  module ConfigType
    class SettingsArray < Base
      extend ::Forwardable

      attr_accessor :size, :elems
      alias_method :value, :itself
      def_delegators :@elems, :[], :count, :each, :each_with_index, :fetch,
        :first, :last, :map, :select

      def initialize(parent:, builder:, size:)
        @size = size
        super(parent:, builder:)
      end

      def length
        @length ||= case size
                    when Proc
                      parent.instance_exec(&size)
                    when Numeric
                      size
                    else
                      raise ::ArgumentError, "size for #{key} must be a number or a proc"
                    end
      end

      def read_value
        @elems = ::Array.new(length) do |i|
          arr = parent.yaml[key] ||= []
          yaml = arr[i] ||= {}

          Class.new(parent.settings_klass).tap do |k|
            k.class_exec(i, &blk)
            # # Trickery to get a block argument at instance level (don't ask me how)
            # k.class_exec do
            #   instance_exec(i, &blk)
            # end
          end.new(key: i, parent: self, yaml:)
        end
      end

      def dump!(user_only: false)
        elems.map { |e| e.dump!(user_only:) }
      end

      def parse(value)
        value
      end

      def inspect
        "#<#{self.class.name} slug:#{slug}, length:#{length}>"
      end
    end
  end
end
