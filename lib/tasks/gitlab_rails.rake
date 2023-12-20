# frozen_string_literal: true

require_relative '../gdk/task_helpers'

desc 'Run GitLab migrations'
task 'gitlab-db-migrate' do
  puts
  GDK::TaskHelpers::RailsMigration.new.migrate
end
