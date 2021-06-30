# frozen_string_literal: true

module Tooling
  module Danger
    module ProjectHelper
      CI_ONLY_RULES ||= %w[
        roulette
      ].freeze

      def rule_names
        helper.ci? ? CI_ONLY_RULES : []
      end

      # First-match win, so be sure to put more specific regex at the top...
      CATEGORIES = {
        %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
        %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,

        %r{.*} => [nil]
      }.freeze

      def changes_by_category
        helper.changes_by_category(CATEGORIES)
      end

      def project_name
        'gitlab-development-kit'
      end
    end
  end
end
