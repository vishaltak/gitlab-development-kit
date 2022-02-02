# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DiffConfig < BaseCommand
      DIFFABLE_FILES = %w[
        Procfile
        gitaly/gitaly.config.toml
        gitaly/praefect.config.toml
        gitaly/config_generated.mak
        gitlab-pages/gitlab-pages.conf
        gitlab-runner-config.toml
        gitlab-shell/.gitlab_shell_secret
        gitlab-shell/config.yml
        gitlab/workhorse/config.toml
        gitlab/config/cable.yml
        gitlab/config/database.yml
        gitlab/config/database_geo.yml
        gitlab/config/gitlab.yml
        gitlab/config/puma.rb
        gitlab/config/resque.yml
        gitlab/config/redis.cache.yml
        gitlab/config/redis.queues.yml
        gitlab/config/redis.shared_state.yml
        gitlab/config/redis.trace_chunks.yml
        gitlab/config/redis.rate_limiting.yml
        gitlab/config/redis.sessions.yml
        nginx/conf/nginx.conf
        openssh/sshd_config
        prometheus/prometheus.yml
        redis/redis.conf
        registry/config.yml
      ].freeze

      def run(_ = [])
        Shellout.new(GDK::MAKE, 'touch-examples').run

        # Iterate over each file from files Array and print any output to
        # stderr that may have come from running `make <file>`.
        #
        results = jobs.map { |x| x.join[:results] }.compact

        results.each do |diff|
          output = diff.output.to_s.chomp
          next if output.empty?

          stdout.puts(diff.file)
          stdout.puts('-' * 80)
          stdout.puts(output)
          stdout.puts("\n")
        end

        true
      end

      private

      def jobs
        DIFFABLE_FILES.map do |file|
          Thread.new do
            Thread.current[:results] = ConfigDiff.new(file)
          end
        end
      end

      class ConfigDiff
        attr_reader :file, :output

        def initialize(file)
          @file = file

          execute
        end

        def file_path
          @file_path ||= GDK.root.join(file)
        end

        private

        def execute
          # It's entirely possible file_path doesn't exist because it may be
          # a config file that user does not need and therefore has not been
          # generated.
          return nil unless file_path.exist?

          update_config_file

          @output = diff_with_unchanged
        ensure
          temporary_diff_file.delete if temporary_diff_file.exist?
        end

        def temporary_diff_file
          @temporary_diff_file ||= GDK.config.gdk_root.join('tmp', "diff_#{file.gsub(%r{/+}, '_')}")
        end

        def update_config_file
          run('rake', "generate-file-at[#{file},#{temporary_diff_file}]")
        end

        def diff_with_unchanged
          run('git', 'diff', '--no-index', '--color', file, temporary_diff_file.to_s)
        end

        def run(*commands)
          Shellout.new(commands, chdir: GDK.root).run
        end
      end
    end
  end
end
