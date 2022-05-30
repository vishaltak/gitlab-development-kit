# frozen_string_literal: true

module GDK
  # GDK Commands
  module Command
    autoload :BaseCommand, 'gdk/command/base_command'
    autoload :Cleanup, 'gdk/command/cleanup'
    autoload :Config, 'gdk/command/config'
    autoload :DebugInfo, 'gdk/command/debug_info'
    autoload :DiffConfig, 'gdk/command/diff_config'
    autoload :Env, 'gdk/command/env'
    autoload :Doctor, 'gdk/command/doctor'
    autoload :Help, 'gdk/command/help'
    autoload :Install, 'gdk/command/install'
    autoload :Kill, 'gdk/command/kill'
    autoload :MeasureBase, 'gdk/command/measure_base'
    autoload :MeasureUrl, 'gdk/command/measure_url'
    autoload :MeasureWorkflow, 'gdk/command/measure_workflow'
    autoload :Open, 'gdk/command/open'
    autoload :Pristine, 'gdk/command/pristine'
    autoload :Psql, 'gdk/command/psql'
    autoload :PsqlGeo, 'gdk/command/psql_geo'
    autoload :Rails, 'gdk/command/rails'
    autoload :Reconfigure, 'gdk/command/reconfigure'
    autoload :RedisCLI, 'gdk/command/redis_cli'
    autoload :Restart, 'gdk/command/restart'
    autoload :ResetData, 'gdk/command/reset_data'
    autoload :ResetPraefectData, 'gdk/command/reset_praefect_data'
    autoload :Run, 'gdk/command/run'
    autoload :Start, 'gdk/command/start'
    autoload :Status, 'gdk/command/status'
    autoload :Stop, 'gdk/command/stop'
    autoload :Tail, 'gdk/command/tail'
    autoload :Thin, 'gdk/command/thin'
    autoload :Trust, 'gdk/command/trust'
    autoload :Update, 'gdk/command/update'
    autoload :Version, 'gdk/command/version'

    # This is a list of existing supported commands and their associated
    # implementation class
    COMMANDS = {
      'cleanup' => -> { GDK::Command::Cleanup },
      'config' => -> { GDK::Command::Config },
      'debug-info' => -> { GDK::Command::DebugInfo },
      'diff-config' => -> { GDK::Command::DiffConfig },
      'doctor' => -> { GDK::Command::Doctor },
      'env' => -> { GDK::Command::Env },
      'install' => -> { GDK::Command::Install },
      'kill' => -> { GDK::Command::Kill },
      'help' => -> { GDK::Command::Help },
      'measure' => -> { GDK::Command::MeasureUrl },
      'measure-workflow' => -> { GDK::Command::MeasureWorkflow },
      'open' => -> { GDK::Command::Open },
      'psql' => -> { GDK::Command::Psql },
      'psql-geo' => -> { GDK::Command::PsqlGeo },
      'pristine' => -> { GDK::Command::Pristine },
      'rails' => -> { GDK::Command::Rails },
      'reconfigure' => -> { GDK::Command::Reconfigure },
      'redis-cli' => -> { GDK::Command::RedisCLI },
      'reset-data' => -> { GDK::Command::ResetData },
      'reset-praefect-data' => -> { GDK::Command::ResetPraefectData },
      'run' => -> { GDK::Command::Run },
      'tail' => -> { GDK::Command::Tail },
      'thin' => -> { GDK::Command::Thin },
      'trust' => -> { GDK::Command::Trust },
      'update' => -> { GDK::Command::Update },
      'version' => -> { GDK::Command::Version }
    }.freeze
  end
end
