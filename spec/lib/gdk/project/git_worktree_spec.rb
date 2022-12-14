# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Project::GitWorktree do
  let(:worktree_path) { Pathname.new('/tmp/something') }
  let(:short_worktree_path) { "#{worktree_path.basename}/" }
  let(:default_branch) { 'main' }
  let(:ref_remote_branch) { 'origin/main' }
  let(:revision) { 'main' }
  let(:current_branch_name) { nil }
  let(:auto_rebase) { nil }
  let(:shallow_clone) { nil }
  let(:stash_nothing_to_save) { 'No local changes to save' }
  let(:stash_saved_something) { 'Saved working directory and index state' }

  describe '#update' do
    shared_examples "it attempts to update the git worktree for 'feature-branch'" do
      let(:current_branch_name) { 'feature-branch' }

      it 'fetches and updates' do
        expect_update(stash_result: stash_nothing_to_save, shallow_clone: shallow_clone)
        auto_rebase ? expect_auto_rebase : expect_checkout_and_pull
        expect(subject.update).to be_truthy
      end

      it 'stash saves, fetches, updates and stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_auto_rebase : expect_checkout_and_pull
        expect_shellout('git stash pop')
        expect(subject.update).to be_truthy
      end

      it 'fetch fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, fetch_success: false, shallow_clone: shallow_clone)
        expect(GDK::Output).to receive(:error).with("Failed to fetch for '#{short_worktree_path}'")
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_auto_rebase(false) : expect_checkout_and_pull(checkout_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_auto_rebase(false) : expect_checkout_and_pull(checkout_success: true, pull_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end
    end

    shared_examples "it attempts to update the git worktree when branch is empty (detached head)" do
      let(:current_branch_name) { '' }

      it 'fetches and updates' do
        expect_update(stash_result: stash_nothing_to_save, shallow_clone: shallow_clone)
        auto_rebase ? expect_just_checkout : expect_checkout_and_pull
        expect(subject.update).to be_truthy
      end

      it 'stash saves, fetches, updates and stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_just_checkout : expect_checkout_and_pull
        expect_shellout('git stash pop')
        expect(subject.update).to be_truthy
      end

      it 'fetch fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, fetch_success: false, shallow_clone: shallow_clone)
        expect(GDK::Output).to receive(:error).with("Failed to fetch for '#{short_worktree_path}'")
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_just_checkout(false) : expect_checkout_and_pull(checkout_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, shallow_clone: shallow_clone)
        auto_rebase ? expect_just_checkout(false) : expect_checkout_and_pull(checkout_success: true, pull_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end
    end

    context 'when the checkout is shallow' do
      let(:shallow_clone) { true }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    context 'when auto_rebase is disabled' do
      let(:auto_rebase) { false }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    context 'when auto_rebase is enabled' do
      let(:auto_rebase) { true }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    def new_subject
      described_class.new(worktree_path, default_branch, revision, auto_rebase: auto_rebase)
    end

    def expect_update(stash_result:, fetch_success: true, shallow_clone: false)
      expect_shellout('git stash save -u', stdout: stash_result)
      expect_shellout('git rev-parse --is-shallow-repository', stdout: shallow_clone.to_s)

      if shallow_clone
        expect_shellout("git fetch --depth 1 origin #{revision}", success: fetch_success)
      else
        expect_shellout('git fetch --all --tags --prune', success: fetch_success)
      end
    end

    def expect_auto_rebase(rebase_success = true)
      expect_shellout('git branch --show-current', stdout: current_branch_name)
      expect_shellout("git rev-parse --abbrev-ref #{default_branch}@{upstream}", stdout: ref_remote_branch)
      stderr = rebase_success ? '' : 'rebase failed'
      expect_shellout("git rebase #{ref_remote_branch} -s recursive -X ours --no-rerere-autoupdate", success: rebase_success, stderr: stderr)
      expect_shellout('git rebase --abort', args: { display_output: false }) unless rebase_success

      if rebase_success
        expect(GDK::Output).to receive(:success).with("Successfully fetched and rebased '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
      else
        expect(GDK::Output).to receive(:puts).with(stderr, stderr: true)
        expect(GDK::Output).to receive(:error).with("Failed to rebase '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
      end
    end

    def expect_checkout_and_pull(checkout_success: true, pull_success: true)
      checkout_stderr = checkout_success ? '' : 'checkout failed'
      expect_shellout("git checkout #{revision}", success: checkout_success, stderr: checkout_stderr)

      if checkout_success
        expect(GDK::Output).to receive(:success).with("Successfully fetched and checked out '#{revision}' for '#{short_worktree_path}'")

        if %w[master main].include?(revision)
          pull_stderr = pull_success ? '' : 'pull failed'
          expect_shellout('git pull --ff-only', success: pull_success, stderr: pull_stderr)

          if pull_success
            expect(GDK::Output).to receive(:success).with("Successfully pulled (--ff-only) for '#{short_worktree_path}'")
          else
            expect(GDK::Output).to receive(:puts).with(pull_stderr, stderr: true)
            expect(GDK::Output).to receive(:error).with("Failed to pull (--ff-only) for for '#{short_worktree_path}'")
          end
        end
      else
        expect(GDK::Output).to receive(:puts).with(checkout_stderr, stderr: true)
        expect(GDK::Output).to receive(:error).with("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'")
      end
    end

    def expect_just_checkout(checkout_success = true)
      checkout_stderr = checkout_success ? '' : 'checkout failed'
      expect_shellout('git branch --show-current', stdout: current_branch_name)
      expect_shellout("git checkout #{revision}", success: checkout_success, stderr: checkout_stderr)

      if checkout_success
        expect(GDK::Output).to receive(:success).with("Successfully fetched and checked out '#{revision}' for '#{short_worktree_path}'")
      else
        expect(GDK::Output).to receive(:puts).with(checkout_stderr, stderr: true)
        expect(GDK::Output).to receive(:error).with("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'")
      end
    end

    def expect_shellout(command, stdout: '', stderr: '', success: true, args: {})
      args[:display_output] ||= false
      args[:retry_attempts] ||= described_class::DEFAULT_RETRY_ATTEMPTS
      shellout_double = instance_double(Shellout, success?: success, read_stdout: stdout, read_stderr: stderr)
      expect(Shellout).to receive(:new).with(command, chdir: worktree_path).and_return(shellout_double)
      expect(shellout_double).to receive(:execute).with(**args).and_return(shellout_double)
      shellout_double
    end
  end
end
