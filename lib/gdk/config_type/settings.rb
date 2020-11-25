# frozen_string_literal: true

module GDK
  module ConfigType
    class Settings < Base
      def instanciate(parent:)
        yaml = parent.yaml.fetch(key, {})

        Class.new(parent.settings_klass).tap do |k|
          k.class_eval(&blk)
        end.new(key: key, parent: parent, yaml: yaml)
      end
    end
  end
end
