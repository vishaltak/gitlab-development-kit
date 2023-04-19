# frozen_string_literal: true

module GDK
  module Diagnostic
    class Bundler < Base
      TITLE = 'Bundler'

      def success?
        gitlab_bundle_config.bundle_path_not_set?
      end

      def detail
        return if success?

        output = []
        output << gitlab_bundle_config.warning_detail
        output.compact.join("\n")
      end

      private

      class BundleConfig
        def initialize(path)
          @path = path
        end

        def bundle_path_not_set?
          @bundle_path_not_set ||= bundle_path.include?('You have not configured a value for `PATH`')
        end

        def warning_detail
          return if bundle_path_not_set?

          <<~WARNING
            #{path} appears to have BUNDLE_PATH configured
            which can cause issues. For more detail,
            visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1315

            #{bundle_path}
          WARNING
        end

        private

        attr_reader :path

        def bundle_path
          @bundle_path ||= Shellout.new('bundle config get PATH', chdir: path)
                                   .execute(display_output: false)
                                   .read_stdout
        end
      end

      def gitlab_bundle_config
        @gitlab_bundle_config ||= BundleConfig.new(config.gitlab.dir)
      end
    end
  end
end
