# frozen_string_literal: true

module GDK
  module Diagnostic
    class Geo < Base
      TITLE = 'Geo'

      def success?
        @success ||= if geo_primary?
                       geo_enabled?
                     elsif geo_secondary?
                       geo_enabled? && geo_database_exists?
                     else
                       (!geo_enabled? && !geo_database_exists?)
                     end
      end

      def detail
        return if success?

        if geo_primary?
          <<~MESSAGE
            GDK could be a Geo primary node. However, geo.enabled is not set to true in your gdk.yml.
            Update your gdk.yml to set geo.enabled to true.

            #{geo_howto_url}
          MESSAGE
        elsif geo_secondary?
          <<~MESSAGE
            GDK is a Geo secondary node. #{database_yml_file} contains the geo database settings but
            geo.enabled is not set to true in your gdk.yml.

            Either update your gdk.yml to set geo.enabled to true or remove
            the geo database settings from #{database_yml_file}

            #{geo_howto_url}
          MESSAGE
        end
      end

      private

      def geo_enabled?
        config.geo.enabled
      end

      def geo_secondary?
        config.geo.secondary
      end

      def geo_primary?
        !geo_secondary?
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
