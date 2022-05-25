# frozen_string_literal: true

require 'gdk'

module GDK
  # TaskHelpers are used by raketasks to include functionality that would not
  # make sense to be part of "regular GDK" API.
  #
  # There is also expectation that because this is tightly coupled with tasks
  # code executed here is allowed to terminate the flow with `exit()` or
  # raise unhandled exceptions.
  #
  # IMPORTANT: Other parts of the codebase should NEVER rely on code inside
  # TaskHelpers.
  module TaskHelpers
    autoload :ClickhouseInstaller, 'gdk/task_helpers/clickhouse_installer'
    autoload :ConfigTasks, 'gdk/task_helpers/config_tasks'
    autoload :RailsMigration, 'gdk/task_helpers/rails_migration'
  end
end
