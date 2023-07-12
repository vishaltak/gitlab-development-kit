# frozen_string_literal: true

module GDK
  module Diagnostic
    class Re2 < Base
      TITLE = 're2'
      SCRIPT = %{"require 're2'; regexp = RE2::Regexp.new('\{', log_errors: false); regexp.error unless regexp.ok?"}

      def success?
        # When re2 and libre2 are out of sync, a seg fault can occur due
        # to some memory corruption (https://github.com/mudge/re2/issues/43).
        # This test doesn't always fail the first time, so repeat the test
        # several times to be sure.
        @success ||=
          5.times do
            return false unless re2_ok?
          end

        true
      end

      def detail
        return if success?

        <<~MESSAGE
          It looks like your system re2 library may have been upgraded, and
          the re2 gem needs to be rebuilt as a result.

          Please run `cd #{config.gitlab.dir} && bundle pristine re2`.
        MESSAGE
      end

      private

      def re2_ok?
        cmd = [config.gdk_root.join('support', 'bundle-exec').to_s, 'ruby', '-e', SCRIPT]
        GDK::Output.debug("cmd=[#{cmd}]")

        sh = Shellout.new(cmd, chdir: config.gitlab.dir.to_s)
        sh.try_run
        sh.success?
      end
    end
  end
end
