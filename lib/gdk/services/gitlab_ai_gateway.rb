# frozen_string_literal: true

module GDK
  module Services
    class GitLabAiGateway < Base
      def name
        'gitlab-ai-gateway'
      end

      def command
        config.gitlab_ai_gateway.__service_command
      end

      def enabled?
        config.gitlab_ai_gateway.enabled?
      end
    end
  end
end
