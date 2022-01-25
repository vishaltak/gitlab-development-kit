# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DebugInfo < BaseCommand
      NEW_ISSUE_LINK = 'https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/new'
      ENV_WILDCARDS = %w[GDK_.* BUNDLE_.* GEM_.*].freeze
      ENV_VARS = %w[
        PATH LANG LANGUAGE LC_ALL LDFLAGS CPPFLAGS PKG_CONFIG_PATH
        LIBPCREDIR RUBY_CONFIGURE_OPTS
      ].freeze

      def run(_ = [])
        stdout.puts separator
        stdout.info review_prompt
        stdout.puts separator

        stdout.puts "Operating system: #{os_name}"
        stdout.puts "Architecture: #{arch}"
        stdout.puts "Ruby version: #{ruby_version}"
        stdout.puts "GDK version: #{gdk_version}"

        stdout.puts
        stdout.puts 'Environment:'

        ENV_VARS.each do |var|
          stdout.puts "#{var}=#{ENV[var]}"
        end

        ENV.each do |var, content|
          next unless matches_regex?(var)

          stdout.puts "#{var}=#{content}"
        end

        if gdk_yml_exists?
          stdout.puts
          stdout.puts 'GDK configuration:'
          stdout.puts gdk_yml
        end

        stdout.puts separator

        true
      end

      private

      def os_name
        shellout('uname -a')
      end

      def arch
        shellout('arch')
      end

      def ruby_version
        shellout('ruby --version')
      end

      def gdk_version
        shellout('git rev-parse --short HEAD', chdir: GDK.root)
      end

      def shellout(cmd, **args)
        Shellout.new(cmd, **args).run
      rescue StandardError => e
        "Unknown (#{e.message})"
      end

      def matches_regex?(var)
        var.match?(combined_env_regex)
      end

      def combined_env_regex
        @combined_env_regex ||= /^#{ENV_WILDCARDS.join('|')}$/
      end

      def gdk_yml
        File.read(GDK::Config::FILE)
      end

      def gdk_yml_exists?
        File.exist?(GDK::Config::FILE)
      end

      def review_prompt
        <<~MESSAGE
          Please review the content below, ensuring any sensitive information such as
             API keys, passwords etc are removed before submitting. To create an issue
             in the GitLab Development Kit project, use the following link:

             #{NEW_ISSUE_LINK}

        MESSAGE
      end

      def separator
        @separator ||= '-' * 80
      end
    end
  end
end
