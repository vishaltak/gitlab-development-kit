# frozen_string_literal: true

require_relative 'settings'

module GDK
  module ConfigType
    class SettingsArray < Settings
      class Instance < Base::Instance
        extend ::Forwardable

        attr_accessor :size, :elems
        alias_method :value, :itself
        def_delegators :@elems, :[], :count, :each, :each_with_index, :fetch,
                       :first, :last, :map, :select

        def initialize(key:, size:, parent:, &blk)
          @key = key
          @parent = parent
          @size = size

          populate(&blk)
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

        def dump!
          elems.map(&:dump!)
        end

        def inspect
          "#<#{self.class.name} slug:#{slug}, length:#{length}>"
        end

        private

        def populate(&blk)
          @elems = ::Array.new(length) do |i|
            yaml = parent.yaml.fetch(key, []).fetch(i, {})

            Class.new(parent.settings_klass).tap do |k|
              # Trickery to get a block argument at instance level (don't ask me how)
              k.class_exec do
                instance_exec(i, &blk)
              end
            end.new(key: i, parent: self, yaml: yaml)
          end
        end
      end

      attr_reader :size

      def initialize(key:, size:, &blk)
        super(key: key, &blk)

        @size = size
      end

      def instanciate(parent:)
        Instance.new(key: key, size: size, parent: parent, &blk)
      end
    end
  end
end
