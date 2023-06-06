# frozen_string_literal: true

desc 'Preflight checks for dependencies'
task 'preflight-checks' do
  checker = GDK::Dependencies::Checker.new
  checker.check_all

  unless checker.error_messages.empty?
    warn checker.error_messages
    exit 1
  end
end

desc 'Preflight Update checks'
task 'preflight-update-checks' do
  postgresql = GDK::Postgresql.new
  if postgresql.installed? && postgresql.upgrade_needed?
    message = <<~MESSAGE
      PostgreSQL data directory is version #{postgresql.current_version} and must be upgraded to version #{postgresql.class.target_version} before GDK can be updated.
    MESSAGE

    GDK::Output.warn(message)

    prompt_response = GDK::Output.prompt("This will run 'support/upgrade-postgresql' to back up and upgrade the PostgreSQL data directory. Are you sure? [y/N]").match?(/\Ay(?:es)*\z/i)
    next unless prompt_response

    postgresql.upgrade

    GDK::Output.success("Successfully ran 'support/upgrade-postgresql' script!")
  end
end
