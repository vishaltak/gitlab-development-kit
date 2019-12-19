# frozen_string_literal: true

require 'fileutils'
require 'digest/md5'

module GDK
  module Command
    class DiffConfig
      KNOWN_DIFFS_FILE = '.known_diffs.txt'

      def run(stdout: $stdout, stderr: $stderr)
        files = %w[
          .ruby-version
          Procfile
          gitlab/config/gitlab.yml
          gitlab/config/database.yml
          gitlab/config/unicorn.rb
          gitlab/config/puma.rb
          gitlab/config/resque.yml
          gitlab-shell/config.yml
          gitlab-shell/.gitlab_shell_secret
          redis/redis.conf
          gitlab-workhorse/config.toml
          gitaly/gitaly.config.toml
          gitaly/praefect.config.toml
          nginx/conf/nginx.conf
        ]

        files = %w[gitlab/config/database.yml]

        file_diffs = files.map do |file|
          ConfigDiff.new(file)
        end

        file_diffs.each do |diff|
          next if diff.output.empty?
          next if diff.md5sum == known_diffs[diff.file]

          stdout.puts(diff.output)
        end
      end

      private

      def known_diffs
        @known_diffs ||= begin
          return {} unless File.exist?(KNOWN_DIFFS_FILE)

          File.readlines(KNOWN_DIFFS_FILE).each_with_object({}) do |line, all|
            md5sum, file = line.chomp.split(/\s+/)
            all[file] = md5sum
          end
        end
      end

      class ConfigDiff
        attr_reader :file, :output, :md5sum

        def initialize(file)
          @file = file

          execute
        end

        def file_path
          @file_path ||= File.join($gdk_root, file)
        end

        private

        def unchanged_file_path
          @unchanged_file_path ||= "#{file_path}.unchanged"
        end

        def execute
          FileUtils.mv(file_path, unchanged_file_path)

          update_config_file
          @output = diff_with_unchanged
          @md5sum = Digest::MD5.hexdigest(File.read(unchanged_file_path))
        ensure
          File.rename(unchanged_file_path, file_path)
        end

        def update_config_file
          run(GDK::MAKE, file)
        end

        def diff_with_unchanged
          run('git', 'diff', '--no-index', '--color', unchanged_file_path, file)
        end

        def run(*commands)
          IO.popen(commands.join(' '), chdir: $gdk_root, &:read).chomp
        end
      end
    end
  end
end
