# frozen_string_literal: true

require 'shellout'

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GEM_REQUIRE_MAPPING = {
        'static_holmes' => 'charlock_holmes',
        'ffi' => 'ffi',
        'gpgme' => 'gpgme',
        'pg' => 'pg',
        'oj' => 'oj'
      }.freeze
      GITLAB_GEMS_WITH_C_CODE_TO_CHECK = GEM_REQUIRE_MAPPING.keys

      def initialize(allow_gem_not_installed: false)
        @allow_gem_not_installed = allow_gem_not_installed

        super()
      end

      def success?
        return false unless bundle_check_ok?

        failed_to_load_gitlab_gems.empty?
      end

      def detail
        return if success?

        return bundle_check_error_message unless bundle_check_ok?

        gitlab_error_message
      end

      private

      def bundle_check_ok?
        exec_cmd("#{bundle_exec_cmd} bundle check") || allow_gem_not_installed?
      end

      def allow_gem_not_installed?
        @allow_gem_not_installed == true
      end

      def failed_to_load_gitlab_gems
        @failed_to_load_gitlab_gems ||= GITLAB_GEMS_WITH_C_CODE_TO_CHECK.reject { |name| gem_ok?(name) }
      end

      def gem_ok?(name)
        # We need to support the situation where it's OK if a Ruby gem is not
        # installed because we could be about to install the GDK for the very
        # first time and the Ruby gem won't be installed.
        gem_installed?(name) ? gem_loads_ok?(name) : allow_gem_not_installed?
      end

      def bundle_exec_cmd
        @bundle_exec_cmd ||= config.gdk_root.join('support', 'bundle-exec')
      end

      def gem_installed?(name)
        exec_cmd("#{bundle_exec_cmd} gem list -i #{name}")
      end

      def gem_loads_ok?(name)
        gem_name = GEM_REQUIRE_MAPPING[name]
        command = -> { exec_cmd("#{bundle_exec_cmd} ruby -r #{gem_name} -e 'nil'") }

        if bundler_available?
          ::Bundler.with_unbundled_env do
            command.call
          end
        else
          command.call
        end
      end

      def exec_cmd(cmd)
        GDK::Output.debug("cmd=[#{cmd}]")

        Shellout.new(cmd, chdir: config.gitlab.dir.to_s).execute(display_output: false, display_error: false).success?
      end

      def bundler_available?
        defined? ::Bundler
      end

      def bundle_check_error_message
        <<~MESSAGE
          There are Ruby gems missing that need to be installed. Try running the following to fix:

            (cd #{config.gitlab.dir} && bundle install)
        MESSAGE
      end

      def gitlab_error_message
        <<~MESSAGE
          The following Ruby Gems appear to have issues:

          #{@failed_to_load_gitlab_gems.join("\n")}

          Try running the following to fix:

            (cd #{config.gitlab.dir} && bundle pristine #{@failed_to_load_gitlab_gems.join(' ')})
        MESSAGE
      end
    end
  end
end
