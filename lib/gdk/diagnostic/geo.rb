# frozen_string_literal: true

module GDK
  module Diagnostic
    class Geo < Base
      TITLE = 'Geo'

      def diagnose
        @success = (geo_database_exists? && geo_enabled?) || (!geo_database_exists? && !geo_enabled?)
      end

      def success?
        @success
      end

      def detail
        <<~MESSAGE
          #{database_yml_file} contains the geo database settings but
          geo.enabled is not set to true in your gdk.yml.

          Either update your gdk.yml to set geo.enabled to true or remove
          the geo database settings from #{database_yml_file}

          #{geo_howto_url}
        MESSAGE
      end

      private

      def geo_enabled?
        config.geo.enabled
      end

      def database_yml_file
        @database_yml_file ||= config.gitlab.dir.join('config', 'database.yml').expand_path.to_s
      end

      def database_yml_file_exists?
        File.exist?(database_yml_file)
      end

      def database_yml_file_content
        return {} unless database_yml_file_exists?

        raw_yaml = File.read(database_yml_file)
        YAML.safe_load(raw_yaml, aliases: true, symbolize_names: true) || {}
      end

      def database_names
        database_yml_file_content[:development].to_h.keys
      end

      def geo_database_exists?
        database_names.include?(:geo)
      end

      def geo_howto_url
        'https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md'
      end
    end
  end
end
