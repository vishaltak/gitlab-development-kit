# frozen_string_literal: true

require 'shellout'
require 'thread'

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GITLAB_GEMS_TO_CHECK = %w[charlock_holmes ffi gpgme pg oj].freeze
      RE2_CHECK_SCRIPT = %{"require 're2'; regexp = RE2::Regexp.new('\{', log_errors: false); regexp.error unless regexp.ok?"}

      def gitlab_bundle_check_ok?
        return @gitlab_bundle_check_ok if defined?(@gitlab_bundle_check_ok)

        @gitlab_bundle_check_ok ||= gitlab_cmd_success?('bundle check')
      end

      def success?
        gitlab_bundle_check_ok? && gitlab_gems_with_problems.empty? && gitlab_re2_ok?
      end

      def detail
        return gitlab_bundle_check_error_message unless gitlab_bundle_check_ok?
        return gitlab_gems_with_problems_error_message unless gitlab_gems_with_problems.empty?
        return gitlab_re2_error_message unless gitlab_re2_ok?
      end

      private

      def gitlab_re2_ok?
        return @gitlab_re2_ok if defined?(@gitlab_re2_ok)

        @gitlab_re2_ok ||= begin
          5.times do
            return false unless gitlab_re2_success?
          end

          true
        end
      end

      def gitlab_re2_success?
        gitlab_cmd_success?([bundle_exec_cmd.to_s, 'ruby', '-e', RE2_CHECK_SCRIPT])
      end

      def gitlab_gems_with_problems
        @gitlab_gems_with_problems ||= begin
          jobs = GITLAB_GEMS_TO_CHECK.map { |name| Thread.new { Thread.current[:results] = { name => gem_ok?(name) } } }

          jobs.each_with_object([]) do |job, all|
            name, result = job.join[:results].flatten
            all << name unless result
          end
        end
      end

      def gem_ok?(name)
        gitlab_cmd_success?("#{bundle_exec_cmd} ruby -r #{name} -e 'nil'")
      end

      def gitlab_cmd_success?(cmd)
        Shellout.new({ 'BUNDLE_GEMFILE' => nil }, cmd, chdir: config.gitlab.dir.to_s).execute(display_output: false, display_error: false).success?
      end

      def gitlab_bundle_check_error_message
        <<~MESSAGE
          There appears to be Ruby gems that are not installed in the GitLab project.

          Try running the following to fix:

          cd #{config.gitlab.dir} && bundle install
        MESSAGE
      end

      def gitlab_gems_with_problems_error_message
        <<~MESSAGE
          The following Ruby Gems appear to have issues in the GitLab project:

          #{@gitlab_gems_with_problems.join("\n")}

          Try running the following to fix:

          cd #{config.gitlab.dir} && gem pristine #{@gitlab_gems_with_problems.join(' ')}
        MESSAGE
      end

      def gitlab_re2_error_message
        're2 seems to have a problem?'
      end
    end
  end
end
