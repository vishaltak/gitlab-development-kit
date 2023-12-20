# frozen_string_literal: true

require 'shellout'

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GITLAB_GEMS_WITH_C_CODE_TO_CHECK = %w[charlock_holmes ffi gpgme pg oj].freeze

      def initialize(allow_gem_not_installed: false)
        @allow_gem_not_installed = allow_gem_not_installed

        super()
      end

      def success?
        failed_to_load_gitlab_gems.empty?
      end

      def detail
        gitlab_error_message unless success?
      end

      private

      attr_reader :allow_gem_not_installed

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
        exec_cmd("#{bundle_exec_cmd} ruby -r #{name} -e 'nil'")
      end

      def exec_cmd(cmd)
        GDK::Output.debug("cmd=[#{cmd}]")

        Shellout.new(cmd, chdir: config.gitlab.dir.to_s).execute(display_output: false, display_error: false).success?
      end

      def gitlab_error_message
        <<~MESSAGE
          The following Ruby Gems appear to have issues:

          #{@failed_to_load_gitlab_gems.join("\n")}

          Try running the following to fix:

          cd #{config.gitlab.dir} && bundle pristine #{@failed_to_load_gitlab_gems.join(' ')}
        MESSAGE
      end
    end
  end
end
