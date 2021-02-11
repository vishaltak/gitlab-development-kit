# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk pristine` command execution
    class Pristine
      GO_CLEAN_CACHE_CMD = 'go clean -cache'
      BUNDLE_INSTALL_CMD = 'bundle install --jobs 4 --quiet'
      BUNDLE_PRISTINE_CMD = 'bundle pristine'
      YARN_CLEAN_CMD = 'yarn clean'

      def run
        if go_clean_cache && gdk_bundle && gitlab_bundle && gitaly_bundle && gitlab_yarn_clean
          GDK::Output.success("Successfully ran 'gdk pristine'!")
          true
        else
          GDK::Output.error("Failed to complete running 'gdk pristine'.")
          GDK.display_help_message
          false
        end
      end

      private

      def notice(msg)
        GDK::Output.notice(msg)
      end

      def go_clean_cache
        notice('Cleaning go cache..')
        shellout(GO_CLEAN_CACHE_CMD)
      end

      def gdk_bundle
        notice('Ensuring GDK Ruby gems are installed and pristine..')
        gdk_bundle_install && gdk_bundle_pristine
      end

      def gdk_bundle_install
        shellout(BUNDLE_INSTALL_CMD, chdir: config.gdk_root)
      end

      def gdk_bundle_pristine
        shellout(BUNDLE_PRISTINE_CMD, chdir: config.gdk_root)
      end

      def gitlab_bundle
        notice('Ensuring gitlab/ Ruby gems are installed and pristine..')
        gitlab_bundle_intstall && gitlab_bundle_pristine
      end

      def gitlab_bundle_intstall
        shellout(BUNDLE_INSTALL_CMD, chdir: config.gitlab.dir)
      end

      def gitlab_bundle_pristine
        shellout(BUNDLE_PRISTINE_CMD, chdir: config.gitlab.dir)
      end

      def gitlab_yarn_clean
        notice('Cleaning GitLab yarn cache..')
        shellout(YARN_CLEAN_CMD, chdir: config.gitlab.dir)
      end

      def gitaly_bundle
        notice('Ensuring gitaly/ruby/ Ruby gems are installed and pristine..')
        gitaly_bundle_install && gitaly_bundle_pristine
      end

      def gitaly_bundle_install
        shellout(BUNDLE_INSTALL_CMD, chdir: config.gitaly.ruby_dir)
      end

      def gitaly_bundle_pristine
        shellout(BUNDLE_PRISTINE_CMD, chdir: config.gitaly.ruby_dir)
      end

      def config
        @config ||= GDK.config
      end

      def shellout(cmd, chdir: config.gdk_root)
        sh = Shellout.new(cmd, chdir: chdir)
        sh.stream
        sh.success?
      rescue StandardError => e
        GDK::Output.puts(e.message, stderr: true)
        false
      end
    end
  end
end
