# frozen_string_literal: true

namespace :gitlab do
  desc 'GitLab: Truncate logs'
  task :truncate_logs, [:prompt] do |_, args|
    if args[:prompt] != 'false'
      GDK::Output.warn("About to truncate gitlab/log/* files.")
      GDK::Output.puts(stderr: true)

      next if ENV.fetch('GDK_GITLAB_TRUNCATE_LOGS_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

      prompt_response = GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      next unless prompt_response

      GDK::Output.puts(stderr: true)
    end

    result = GDK.config.gitlab.log_dir.glob('*').map { |file| file.truncate(0) }.all?(0)
    raise 'Truncation of gitlab/log/* files failed.' unless result

    GDK::Output.success('Truncated gitlab/log/* files.')
  end
end
