# frozen_string_literal: true

module GDK
  module Services
    # MinIO Object Storage service
    class Minio < Base
      def name
        'minio'
      end

      def command
        %(minio server -C minio/config --address "#{address}" --compat minio/data)
      end

      def enabled?
        config.object_store?
      end

      def env
        {
          MINIO_REGION: 'gdk',
          MINIO_ACCESS_KEY: 'minio',
          MINIO_SECRET_KEY: 'gdk-minio'
        }
      end

      private

      def address
        "#{config.object_store.host}:#{config.object_store.port}"
      end
    end
  end
end
