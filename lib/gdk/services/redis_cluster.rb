# frozen_string_literal: true

module GDK
  module Services
    # Redis server in cluster mode
    class RedisCluster < Required
      def name
        'redis-cluster'
      end

      def command
        %(support/redis-cluster-signal-wrapper #{cluster_size} #{port} #{redis_config_dir})
      end

      private

      def redis_config_dir
        config.redis_cluster.dir
      end

      def cluster_size
        config.redis_cluster.clusters
      end

      def port
        config.redis_cluster.port
      end
    end
  end
end
