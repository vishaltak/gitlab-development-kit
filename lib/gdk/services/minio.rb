# frozen_string_literal: true

module GDK
  module Services
    # MinIO Object Storage service
    class Minio < Base
      def name
        'minio'
      end

      def command
        %(minio server -C minio/config --address "#{address}" --console-address "#{console_address}" --compat "#{data_dir}")
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

      def data_dir
        GDK.root.join('minio/data')
      end

      private

      def address
        "#{config.object_store.host}:#{config.object_store.port}"
      end

      def console_address
        "#{config.object_store.host}:#{config.object_store.console_port}"
      end
    end
  end
end
