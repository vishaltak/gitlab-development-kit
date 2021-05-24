# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk init` command execution
    #
    # @deprecated GDK init command has been deprecated should be removed in a future update
    class Init < BaseCommand
      DEFAULT_INIT_DIRECTORY = 'gitlab-development-kit'

      def run(args = [])
        GDK::Output.info("'gdk init' is deprecated and will be removed in a future update.")

        if show_help?(args)
          GDK::Output.puts('Usage: gdk init [DIR]')

          return true
        end

        directory = new_gdk_directory(args)
        if new_gdk_directory_invalid?(directory)
          GDK::Output.error('The GDK directory cannot start with a dash.')

          return false
        end

        if clone_gdk(directory)
          GDK::Output.success("Successfully git cloned the GDK into '#{directory}'.")

          true
        else
          GDK::Output.error("An error occurred while attempting to git clone the GDK into '#{directory}'.")

          false
        end
      end

      private

      def show_help?(args)
        args.count > 1 || (args & %w[-help --help]).any?
      end

      def new_gdk_directory_invalid?(directory)
        directory.start_with?('-')
      end

      def new_gdk_directory(args)
        args.count == 1 ? args.first : DEFAULT_INIT_DIRECTORY
      end

      def clone_gdk(directory)
        cmd = "git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git #{directory}"
        sh = Shellout.new(cmd)
        sh.stream

        sh.success?
      end
    end
  end
end
