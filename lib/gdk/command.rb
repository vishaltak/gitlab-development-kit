# frozen_string_literal: true

module GDK
  module Command
    autoload :Config, 'gdk/command/config'
    autoload :DiffConfig, 'gdk/command/diff_config'
    autoload :Doctor, 'gdk/command/doctor'
    autoload :Help, 'gdk/command/help'
    autoload :Install, 'gdk/command/install'
    autoload :MeasureBase, 'gdk/command/measure_base'
    autoload :MeasureUrl, 'gdk/command/measure_url'
    autoload :MeasureWorkflow, 'gdk/command/measure_workflow'
    autoload :Pristine, 'gdk/command/pristine'
    autoload :Reconfigure, 'gdk/command/reconfigure'
    autoload :ResetData, 'gdk/command/reset_data'
    autoload :Run, 'gdk/command/run'
    autoload :Thin, 'gdk/command/thin'
    autoload :Update, 'gdk/command/update'
  end
end
