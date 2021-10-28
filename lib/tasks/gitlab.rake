# frozen_string_literal: true

namespace :gitlab do
  desc 'GitLab: Truncate logs'
  task :truncate_logs do
    result = GDK.config.gitlab.log_dir.glob('*').map { |file| file.truncate(0) }.all?(0)
    raise 'Truncation of gitlab/log/* files failed.' unless result

    GDK::Output.success('Truncated gitlab/log/* files.')
  end
end
