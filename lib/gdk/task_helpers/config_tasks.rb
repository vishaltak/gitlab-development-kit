# frozen_string_literal: true

module GDK
  module TaskHelpers
    # A rake or make task
    Task = Struct.new(:name, :make_dependencies, :template, :erb_extra_args, :post_render,
                      :no_op_condition, :timed, keyword_init: true) do
      def initialize(attributes)
        super

        self[:make_dependencies] = (attributes[:make_dependencies] || []).join(' ')
        self[:template] ||= "support/templates/#{self[:name]}.erb"
        self[:erb_extra_args] ||= {}
        self[:timed] = false if self[:timed].nil?
      end
    end

    # Class to handle config tasks templates and make targets
    class ConfigTasks
      include Singleton

      def initialize
        @template_tasks = []
        @make_tasks = []
      end

      def add_template(**args)
        @template_tasks << Task.new(**args)
      end

      def add_make_task(**args)
        @make_tasks << Task.new(**args)
      end

      def template_tasks
        @template_tasks.clone
      end

      def make_tasks
        @make_tasks.clone
      end

      def all_tasks
        template_tasks + make_tasks
      end
    end
  end
end
