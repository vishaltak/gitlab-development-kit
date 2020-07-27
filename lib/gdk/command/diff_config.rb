# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DiffConfig
      def run(stdout: $stdout, stderr: $stderr)
        files = {
          'Procfile' => -> { true },
          'gitaly/gitaly.config.toml' => -> { true },
          'gitaly/praefect.config.toml' => -> { true },
          'gitlab-pages/gitlab-pages.conf' => -> { true },
          'gitlab-runner-config.toml' => -> { GDK.config.runner? },
          'gitlab-shell/.gitlab_shell_secret' => -> { true },
          'gitlab-shell/config.yml' => -> { true },
          'gitlab-workhorse/config.toml' => -> { true },
          'gitlab/config/cable.yml' => -> { true },
          'gitlab/config/database.yml' => -> { true },
          'gitlab/config/database_geo.yml' => -> { true },
          'gitlab/config/gitlab.yml' => -> { true },
          'gitlab/config/puma.rb' => -> { true },
          'gitlab/config/resque.yml' => -> { true },
          'gitlab/config/unicorn.rb' => -> { true },
          'nginx/conf/nginx.conf' => -> { true },
          'openssh/sshd_config' => -> { true },
          'prometheus/prometheus.yml' => -> { true },
          'redis/redis.conf' => -> { true },
          'registry/config.yml' => -> { true }
        }

        jobs = files.each_with_object([]) do |(file, to_process), all|
          next unless to_process.call

          all << Thread.new do
            Thread.current[:results] = ConfigDiff.new(file)
          end
        end

        file_diffs = jobs.map { |x| x.join[:results] }.compact

        # Iterate over each file from files Array and print any output to
        # stderr that may have come from running `make <file>`.
        #
        file_diffs.each do |diff|
          output = diff.make_output.to_s.chomp
          next if output.empty?

          stderr.puts(output)
        end

        # Iterate over each file from files Array and print any output to
        # stdout that may have come from running `git diff <file>.unchanged`
        # which is how we know what _would_ happen if we ran `gdk reconfigure`
        #
        file_diffs.each do |diff|
          next if diff.output.to_s.empty?

          stdout.puts(diff.output)
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
          # It's entirely possible file_path doesn't exist because it may be
          # a config file that user does not need and therefore has not been
          # generated.
          return nil unless file_path.exist?

          File.rename(file_path, file_path_unchanged)

          @make_output = update_config_file

          @output = diff_with_unchanged
        ensure
          File.rename(file_path_unchanged, file_path) if File.exist?(file_path_unchanged)
        end

        def file_path_unchanged
          @file_path_unchanged ||= "#{file_path}.unchanged"
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
