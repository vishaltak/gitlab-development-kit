# frozen_string_literal: true

require 'fileutils'

module GDK
  module Command
    class DebugInfo < BaseCommand
      def run(_ = [])
        stdout.puts review_prompt
        stdout.puts separator

        stdout.puts "Operating system: #{os_name}"
        stdout.puts "Architecture: #{arch}"
        stdout.puts "Ruby version: #{ruby_version}"
        stdout.puts "GDK version: #{gdk_version}"

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

      def gdk_yml
        File.read(GDK::Config::FILE)
      end

      def gdk_yml_exists?
        File.exist?(GDK::Config::FILE)
      end

      def review_prompt
        <<~MESSAGE
          Please review the content below, ensuring any sensitive information such as API
          keys, passwords etc are removed before submitting:

        MESSAGE
      end

      def separator
        @separator ||= '-' * 80
      end
    end
  end
end
