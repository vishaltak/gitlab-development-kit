# frozen_string_literal: true

require_relative '../gdk/gitlab_rails/db'

desc 'Run GitLab migrations'
task 'gitlab-db-migrate' do
  puts
  GDK::GitlabRails::DB.new.migrate
end
