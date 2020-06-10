# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DiffConfig
      def run(stdout: $stdout, stderr: $stderr)
        files = %w[
          .ruby-version
          Procfile
          gitaly/gitaly.config.toml
          gitaly/praefect.config.toml
          gitlab-shell/.gitlab_shell_secret
          gitlab-shell/config.yml
          gitlab-workhorse/config.toml
          gitlab/config/cable.yml
          gitlab/config/database.yml
          gitlab/config/gitlab.yml
          gitlab/config/puma.rb
          gitlab/config/resque.yml
          gitlab/config/unicorn.rb
          nginx/conf/nginx.conf
          redis/redis.conf
        ]

        file_diffs = files.map do |file|
          ConfigDiff.new(file)
        end

        file_diffs.each do |diff|
          output = diff.make_output.chomp
          stderr.puts(output) unless output.empty?
        end

        file_diffs.each do |diff|
          stdout.puts diff.output unless diff.output == ""
        end
      end

      class ConfigDiff
        attr_reader :file, :output, :make_output

        def initialize(file)
          @file = file

          execute
        end

        def file_path
          @file_path ||= GDK.root.join(file)
        end

        private

        def execute
          FileUtils.mv(file_path, "#{file_path}.unchanged")

          @make_output = update_config_file

          @output = diff_with_unchanged
        ensure
          File.rename("#{file_path}.unchanged", file_path)
        end

        def update_config_file
          run(GDK::MAKE, file)
        end

        def diff_with_unchanged
          run('git', 'diff', '--no-index', '--color', "#{file}.unchanged", file)
        end

        def run(*commands)
          IO.popen(commands.join(' '), chdir: GDK.root, &:read).chomp
        end
      end
    end
  end
end
