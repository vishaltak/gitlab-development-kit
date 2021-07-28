# frozen_string_literal: true

module GDK
  module Diagnostic
    class Gitlab < Base
      TITLE = 'GitLab'

      def diagnose
        nil
      end

      def success?
        gitlab_shell_secret_diagnostic.success?
      end

      def detail
        return if success?

        gitlab_shell_secret_diagnostic.detail
      end

      private

      def gitlab_shell_secret_diagnostic
        @gitlab_shell_secret_diagnostic ||= GitlabShellSecretDiagnostic.new(config)
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
    end
  end
end
