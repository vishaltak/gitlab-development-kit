# frozen_string_literal: true

module GDK
  # Data types used by the Config/Settings DSL
  module ConfigType
    autoload :Anything, 'gdk/config_type/anything'
    autoload :Array, 'gdk/config_type/array'
    autoload :Base, 'gdk/config_type/base'
    autoload :Bool, 'gdk/config_type/bool'
    autoload :Builder, 'gdk/config_type/builder'
    autoload :Hash, 'gdk/config_type/hash'
    autoload :Integer, 'gdk/config_type/integer'
    autoload :Mergable, 'gdk/config_type/mergable'
    autoload :Path, 'gdk/config_type/path'
    autoload :Settings, 'gdk/config_type/settings'
    autoload :SettingsArray, 'gdk/config_type/settings_array'
    autoload :String, 'gdk/config_type/string'
  end
end
