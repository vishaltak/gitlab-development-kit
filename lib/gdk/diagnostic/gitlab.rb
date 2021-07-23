# frozen_string_literal: true

module GDK
  module Diagnostic
    class Gitlab < Base
      TITLE = 'GitLab'

      def diagnose
        nil
      end

      def success?
        gitlab_shell_secret_matches?
      end

      def detail
        return if success?

        <<~SECRET_MISMATCH_MSG
          The gitlab-shell secret files need to match but they don't:

          #{gitlab_shell_secret_in_gitlab}
          #{'-' * gitlab_shell_secret_in_gitlab.to_s.length}
          #{gitlab_shell_secret_in_gitlab_contents}

          #{gitlab_shell_secret_in_gitlab_shell}
          #{'-' * gitlab_shell_secret_in_gitlab_shell.to_s.length}
          #{gitlab_shell_secret_in_gitlab_shell_contents}
        SECRET_MISMATCH_MSG
      end

      private

      def gitlab_shell_secret_matches?
        gitlab_shell_secret_in_gitlab_contents == gitlab_shell_secret_in_gitlab_shell_contents
      end

      def gitlab_shell_secret_in_gitlab
        config.gitlab.dir.join('.gitlab_shell_secret')
      end

      def gitlab_shell_secret_in_gitlab_contents
        @gitlab_shell_secret_in_gitlab_contents ||= gitlab_shell_secret_in_gitlab.read.chomp
      end

      def gitlab_shell_secret_in_gitlab_shell
        config.gitlab_shell.dir.join('.gitlab_shell_secret')
      end

      def gitlab_shell_secret_in_gitlab_shell_contents
        @gitlab_shell_secret_in_gitlab_shell_contents ||= gitlab_shell_secret_in_gitlab_shell.read.chomp
      end
    end
  end
end
