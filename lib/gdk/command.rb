# frozen_string_literal: true

module GDK
  module Command
    autoload :Config, 'gdk/command/config'
    autoload :DiffConfig, 'gdk/command/diff_config'
    autoload :Doctor, 'gdk/command/doctor'
    autoload :Measure, 'gdk/command/measure'
    autoload :Help, 'gdk/command/help'
    autoload :Reconfigure, 'gdk/command/reconfigure'
  end
end
