# frozen_string_literal: true

module GDK
  module Project
    class Base
      ProjectHandledError = Class.new(StandardError)

      def initialize(name, worktree_path, default_branch)
        @name = name
        @worktree_path = worktree_path
        @default_branch = default_branch
      end

      def update(revision)
        check_auto_update!

        GitWorktree.new(worktree_path, default_branch, revision, auto_rebase: config.gdk.auto_rebase_projects?).update
      rescue ProjectHandledError => e
        GDK::Output.warn(e.message)
        nil
      end

      private

      attr_reader :name, :worktree_path, :default_branch

      def config
        @config ||= GDK.config
      end

      def component_config
        @component_config ||= config.dig(name) # rubocop:disable Style/SingleArgumentDig
      rescue GDK::ConfigSettings::SettingUndefined
        raise ProjectHandledError, "Unknown component '#{name}'"
      end

      def check_auto_update!
        return if component_config.auto_update?

        raise ProjectHandledError, "Auto update for '#{name}' is disabled"
      end
    end
  end
end
