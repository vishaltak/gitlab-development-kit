# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DiffConfig < BaseCommand
      def run(_ = [])
        Shellout.new(GDK::MAKE, 'touch-examples').run

        # Iterate over each file from files Array and print any output to
        # stderr that may have come from running `make <file>`.
        #
        results = jobs.filter_map { |x| x.join[:results] }

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
