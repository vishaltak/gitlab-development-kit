# frozen_string_literal: true

module GDK
  module Project
    class GitWorktree
      DEFAULT_RETRY_ATTEMPTS = 3

      def initialize(worktree_path, default_branch, revision, auto_rebase: false)
        @worktree_path = worktree_path
        @default_branch = default_branch
        @revision = revision
        @auto_rebase = auto_rebase
      end

      def update
        stashed = stash_save

        unless fetch
          GDK::Output.error("Failed to fetch for '#{short_worktree_path}'")
          return false
        end

        result = auto_rebase? ? execute_rebase : execute_checkout_and_pull
      ensure
        stashed ? stash_pop : result
      end

      private

      attr_reader :worktree_path, :default_branch, :revision, :auto_rebase
      alias_method :auto_rebase?, :auto_rebase

      def short_worktree_path
        "#{worktree_path.basename}/"
      end

      def execute_command(command, **args)
        args[:display_output] ||= false
        args[:retry_attempts] ||= DEFAULT_RETRY_ATTEMPTS

        Shellout.new(command, chdir: worktree_path).execute(**args)
      end

      def execute_rebase
        current_branch_name.empty? ? checkout_revision : rebase
      end

      def execute_checkout_and_pull
        checkout_revision && pull_ff_only
      end

      def checkout_revision
        sh = execute_command("git checkout #{revision}")
        if sh.success?
          GDK::Output.success("Successfully fetched and checked out '#{revision}' for '#{short_worktree_path}'")
          true
        else
          GDK::Output.puts(sh.read_stderr, stderr: true)
          GDK::Output.error("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'")
          false
        end
      end

      def pull_ff_only
        return true unless revision_is_default?

        sh = execute_command('git pull --ff-only')
        if sh.success?
          GDK::Output.success("Successfully pulled (--ff-only) for '#{short_worktree_path}'")
          true
        else
          GDK::Output.puts(sh.read_stderr, stderr: true)
          GDK::Output.error("Failed to pull (--ff-only) for for '#{short_worktree_path}'")
          false
        end
      end

      def revision_is_default?
        %w[master main].include?(revision)
      end

      def current_branch_name
        @current_branch_name ||= execute_command('git branch --show-current').read_stdout
      end

      def stash_save
        sh = execute_command('git stash save -u')
        sh.success? && sh.read_stdout != 'No local changes to save'
      end

      def stash_pop
        execute_command('git stash pop').success?
      end

      def fetch
        execute_command('git fetch --all --tags --prune').success?
      end

      def rebase
        sh = execute_command("git rebase #{ref_remote_branch} -s recursive -X ours --no-rerere-autoupdate")
        if sh.success?
          GDK::Output.success("Successfully fetched and rebased '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
          true
        else
          GDK::Output.puts(sh.read_stderr, stderr: true)
          GDK::Output.error("Failed to rebase '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
          execute_command('git rebase --abort', display_output: false)
          false # Always send false as the initial 'git rebase' failed.
        end
      end

      def ref_remote_branch
        sh = execute_command("git rev-parse --abbrev-ref #{default_branch}@{upstream}")
        sh.success? ? sh.read_stdout : revision
      end
    end
  end
end
