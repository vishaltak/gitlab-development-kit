# frozen_string_literal: true

require 'rake'

module GDK
  module Modules
    class Base
      private

      def gdk_config
        @gdk_config ||= GDK.config
      end

      def hostname
        gdk_config.hostname
      end

      def generate_file_if_not_exist(file, rake_task_name, rake_task_file)
        return true if file.exist?

        execute_rake_task(rake_task_name, rake_task_file)
      end

      def execute_rake_task(name, file, args: nil)
        Kernel.load(GDK.root.join('lib', 'tasks', file))

        Rake::Task[name].invoke(args)
        true
      end
    end
  end
end
