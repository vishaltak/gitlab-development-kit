# frozen_string_literal: true

require_relative '../gdk/vault'

namespace :vault do
  desc 'Vault configuration for a specific GitLab project'

  task :configure, [:project_id] do |_, args|
    vault = GDK::Vault.new

    vault.create_test_secret
    vault.create_test_policy
    vault.configure_test_auth(args[:project_id])
  end
end
