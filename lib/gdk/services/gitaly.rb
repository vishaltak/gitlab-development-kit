# frozen_string_literal: true

module GDK
  module Services
    class Gitaly < Required
      def name
        'gitaly'
      end

      def command
        %(#{config.gitaly.__gitaly_build_bin_path} serve #{config.gitaly.config_file})
      end

      def enabled?
        config.gitaly.enabled?
      end

      def env
        config.gitaly.env.merge(
          GITALY_TESTING_ENABLE_ALL_FEATURE_FLAGS: config.gitaly.enable_all_feature_flags?
        )
      end

      def exec_dir
        config.gitaly.dir
      end
    end
  end
end
