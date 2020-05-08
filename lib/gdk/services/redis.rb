# frozen_string_literal: true

module GDK
  module Services
    class Redis < Required
      def name
        'redis'
      end

      def command
        %(redis-server #{redis_config})
      end

      private

      def redis_config
        config.redis.dir.join('redis.conf')
      end
    end
  end
end
