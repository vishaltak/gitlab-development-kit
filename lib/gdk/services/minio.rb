# frozen_string_literal: true

module GDK
  module Services
    class Minio < Base
      def name
        'minio'
      end

      def command
        %(env MINIO_REGION=gdk MINIO_ACCESS_KEY=minio MINIO_SECRET_KEY=gdk-minio minio server -C minio/config --address "#{address}" --compat minio/data)
      end

      def enabled?
        settings.enabled?
      end

      private

      def settings
        @settings ||= config.object_store
      end

      def address
        "#{config.hostname}:#{settings.port}"
      end
    end
  end
end
