# frozen_string_literal: true

require 'shellout'

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GITLAB_GEMS_TO_CHECK = %w[charlock_holmes ffi gpgme pg oj].freeze

      def diagnose
        # no-op
      end

      def success?
        failed_to_load_gitlab_gems.empty?
      end

      def detail
        return gitlab_error_message unless failed_to_load_gitlab_gems.empty?
      end

      private

      def failed_to_load_gitlab_gems
        @failed_to_load_gitlab_gems ||= GITLAB_GEMS_TO_CHECK.reject do |name|
          gem_ok?(name, config.gitlab.dir.to_s)
        end
      end

      def gem_ok?(name, chdir)
        cmd = "#{config.gdk_root.join('support', 'bundle-exec')} gem list -i #{name}"
        GDK::Output.debug("cmd=[#{cmd}]")

        sh = Shellout.new(cmd, chdir: chdir)
        sh.try_run
        sh.success?
      end

      def gitlab_error_message
        <<~MESSAGE
          The following Ruby Gems appear to have issues:

          #{@failed_to_load_gitlab_gems.join("\n")}

          Try running the following to fix:

          cd #{config.gitlab.dir} && gem pristine #{@failed_to_load_gitlab_gems.join(' ')}
        MESSAGE
      end
    end
  end
end
