# frozen_string_literal: true

require 'pathname'

module GDK
  module Diagnostic
    class Gitlab < Base
      TITLE = 'GitLab'

      def diagnose
        nil
      end

      def success?
        gitlab_shell_secret_diagnostic.success? && gitlab_log_dir_diagnostic.success?
      end

      def detail
        return if success?

        output = []

        output << gitlab_shell_secret_diagnostic.detail unless gitlab_shell_secret_diagnostic.success?
        output << gitlab_log_dir_diagnostic.detail unless gitlab_log_dir_diagnostic.success?

        output.compact.join("\n")
      end

      private

      def gitlab_shell_secret_diagnostic
        @gitlab_shell_secret_diagnostic ||= GitlabShellSecretDiagnostic.new(config)
      end

      def gitlab_log_dir_diagnostic
        @gitlab_log_dir_diagnostic ||= GitlabLogDirDiagnostic.new(config)
      end

      class GitlabShellSecretDiagnostic
        GITLAB_SHELL_SECRET_FILE = '.gitlab_shell_secret'

        def initialize(config)
          @config = config
        end

        def success?
          both_files_exist? && contents_match?
        end

        def detail
          return if success?

          if !both_files_exist?
            file_doesnt_exist_detail + solution_detail
          elsif !contents_match?
            contents_match_detail + solution_detail
          end
        end

        private

        attr_reader :config

        def solution_detail
          <<~SOLUTION_MESSAGE

            The typical solution is to run 'gdk reconfigure'
          SOLUTION_MESSAGE
        end

        def both_files_exist?
          gitlab_shell_secret_in_gitlab.exist? && gitlab_shell_secret_in_gitlab_shell.exist?
        end

        def file_doesnt_exist_detail
          output = ["The folllowing #{GITLAB_SHELL_SECRET_FILE} files don't exist but need to:", '']
          output << "  #{gitlab_shell_secret_in_gitlab}" unless gitlab_shell_secret_in_gitlab.exist?
          output << "  #{gitlab_shell_secret_in_gitlab_shell}" unless gitlab_shell_secret_in_gitlab_shell.exist?

          "#{output.join("\n")}\n"
        end

        def contents_match?
          gitlab_shell_secret_in_gitlab_contents == gitlab_shell_secret_in_gitlab_shell_contents
        end

        def contents_match_detail
          <<~CONTENT_MISMATCH_MESSSGE
            The gitlab-shell secret files need to match but they don't:

            #{gitlab_shell_secret_in_gitlab}
            #{'-' * gitlab_shell_secret_in_gitlab.to_s.length}
            #{gitlab_shell_secret_in_gitlab_contents}

            #{gitlab_shell_secret_in_gitlab_shell}
            #{'-' * gitlab_shell_secret_in_gitlab_shell.to_s.length}
            #{gitlab_shell_secret_in_gitlab_shell_contents}
          CONTENT_MISMATCH_MESSSGE
        end

        def gitlab_shell_secret_in_gitlab
          config.gitlab.dir.join(GITLAB_SHELL_SECRET_FILE)
        end

        def gitlab_shell_secret_in_gitlab_contents
          @gitlab_shell_secret_in_gitlab_contents ||= gitlab_shell_secret_in_gitlab.read.chomp
        end

        def gitlab_shell_secret_in_gitlab_shell
          config.gitlab_shell.dir.join(GITLAB_SHELL_SECRET_FILE)
        end

        def gitlab_shell_secret_in_gitlab_shell_contents
          @gitlab_shell_secret_in_gitlab_shell_contents ||= gitlab_shell_secret_in_gitlab_shell.read.chomp
        end
      end

      class GitlabLogDirDiagnostic
        LOG_DIR_SIZE_NOT_OK_MB = 1024
        BYTES_TO_MEGABYTES = 1_048_576

        def initialize(config)
          @config = config
        end

        def success?
          log_dir_size_ok?
        end

        def detail
          return if success?

          <<~LOG_DIR_SIZE_NOT_OK
            Your gitlab/log/ directory is #{log_dir_size}MB.  You can truncate the log files if you wish
            by running:

              cd #{config.gdk_root} && rake gitlab:truncate_logs
          LOG_DIR_SIZE_NOT_OK
        end

        private

        attr_reader :config

        def log_dir_size_ok?
          return true unless config.gitlab.log_dir.exist?

          log_dir_size <= LOG_DIR_SIZE_NOT_OK_MB
        end

        def log_dir_size
          @log_dir_size ||= config.gitlab.log_dir.glob('*').sum(&:size) / 1_048_576
        end
      end
    end
  end
end
