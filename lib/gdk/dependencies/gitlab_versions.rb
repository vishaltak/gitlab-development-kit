# frozen_string_literal: true

require 'net/http'

module GDK
  module Dependencies
    class GitlabVersions
      REPOSITORY_RAW_URL = 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/'

      VersionNotDetected = Class.new(StandardError)

      # Return GitLab's ruby version from local repository
      # or fallback to remote repository when no code is still installed
      #
      # @return [String] ruby version
      def ruby_version
        (local_ruby_version || remote_ruby_version).tap do |version|
          raise(VersionNotDetected, "Failed to determine GitLab's Ruby version") unless version.match?(/^[0-9]\.[0-9]+(.[0-9]+)/)
        end
      end

      private

      # Return GitLab's ruby version from local repository
      #
      # @return [String] ruby version
      def local_ruby_version
        read_gitlab_local_file('.ruby-version')
      end

      # Return GitLab's ruby version from remote repository
      #
      # @return [String] ruby version
      def remote_ruby_version
        read_gitlab_remote_file('.ruby-version')
      end

      # Read content from file in `gitlab` folder
      #
      # @param [String] filename
      # @return [String,False] version or false
      def read_gitlab_local_file(filename)
        file = GDK.root.join('gitlab', filename)

        file.exist? ? file.read.strip : false
      end

      # Read content from a file in `gitlab` remote repository
      #
      # @param [String] filename
      def read_gitlab_remote_file(filename)
        uri = URI(File.join(REPOSITORY_RAW_URL, filename))

        Net::HTTP.get(uri).strip
      rescue SocketError
        abort 'Internet connection is required to set up GDK, please ensure you have an internet connection'
      end
    end
  end
end
