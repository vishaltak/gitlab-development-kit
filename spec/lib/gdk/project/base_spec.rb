# frozen_string_literal: true

RSpec.describe GDK::Project::Base do
  let(:name) { nil }
  let(:worktree_path) { '/tmp/something' }
  let(:default_branch) { 'main' }
  let(:revision) { 'main' }

  subject { described_class.new(name, worktree_path, default_branch) }

  describe '#update' do
    context 'when project name is unknown' do
      let(:name) { 'bad' }

      it 'warns and returns nil' do
        expect(GDK::Output).to receive(:warn).with("Unknown component 'bad'")

        expect(subject.update(revision)).to be_nil
      end
    end

    context 'when project name is known' do
      let(:name) { 'gitlab' }
      let(:auto_rebase_projects) { nil }

      before do
        stub_gdk_yaml('gdk' => { 'auto_rebase_projects' => auto_rebase_projects }, 'gitlab' => { 'auto_update' => auto_update })
      end

      context 'but auto_update is disabled' do
        let(:auto_update) { false }

        it 'warns and returns nil' do
          expect(GDK::Output).to receive(:warn).with("Auto update for '#{name}' is disabled")

          expect(subject.update(revision)).to be_nil
        end
      end

      context 'and auto_update is enabled' do
        let(:auto_update) { true }

        shared_examples "it's about to update the git worktree" do
          it 'attempts to run GitWorktree#update' do
            git_worktree_double = instance_double(GDK::Project::GitWorktree, update: true)
            expect(GDK::Project::GitWorktree).to receive(:new).with(worktree_path, default_branch, revision, auto_rebase: auto_rebase_projects).and_return(git_worktree_double)

            expect(subject.update(revision)).to be(true)
          end
        end

        context 'with auto_rebase_projects disabled' do
          let(:auto_rebase_projects) { false }

          it_behaves_like "it's about to update the git worktree"
        end

        context 'with auto_rebase_projects enabled' do
          let(:auto_rebase_projects) { true }

          it_behaves_like "it's about to update the git worktree"
        end
      end
    end
  end
end
