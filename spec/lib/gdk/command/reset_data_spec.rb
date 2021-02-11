# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::ResetData do
  subject { described_class.new }

  describe '.prompt_and_run' do
    let(:are_you_sure) { nil }

    before do
      allow(GDK::Output).to receive(:warn).with("We're about to remove PostgreSQL data, Rails uploads and git repository data.")
      allow(GDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(are_you_sure)
    end

    context 'when the user does not accept / aborts the prompt' do
      let(:are_you_sure) { 'n' }

      it 'does not run' do
        expect(described_class).not_to receive(:new)

        described_class.prompt_and_run
      end
    end

    context 'when the user accepts the prompt' do
      let(:are_you_sure) { 'y' }

      it 'runs' do
        expect(described_class).to receive_message_chain(:new, :run)

        described_class.prompt_and_run
      end
    end
  end

  describe '#run' do
    let!(:root) { GDK.root }
    let!(:time_now) { Time.now }
    let!(:current_timestamp) { time_now.strftime('%Y-%m-%d_%H.%M.%S') }
    let!(:postgresql_data_directory) { root.join('postgresql/data') }
    let!(:new_postgresql_data_directory) { root.join("postgresql/data.#{current_timestamp}") }

    before do
      allow(GDK).to receive(:remember!)
      allow(Runit).to receive(:stop)
      allow(GDK).to receive(:root).and_return(root)
    end

    context 'when backup data script fails' do
      it 'errors out', :hide_stdout do
        freeze_time do
          stub_postgres_data_move
          allow(File).to receive(:rename).with(postgresql_data_directory, new_postgresql_data_directory).and_raise(Errno::ENOENT)

          expect(GDK::Output).to receive(:error).with("Failed to rename directory '#{postgresql_data_directory}' to '#{new_postgresql_data_directory}' - No such file or directory")
          expect(GDK::Output).to receive(:error).with('Failed to backup data.')
          expect(GDK).to receive(:display_help_message)
          expect(GDK).not_to receive(:make)

          subject.run
        end
      end
    end

    context 'when backup data script succeeds', :hide_stdout do
      let!(:rails_uploads_directory) { root.join('gitlab/public/uploads') }
      let!(:new_rails_uploads_directory) { root.join("gitlab/public/uploads.#{current_timestamp}") }
      let!(:git_repository_data_directory) { root.join('repositories') }
      let!(:new_git_repository_data_directory) { root.join("repositories.#{current_timestamp}") }

      context 'but make command fails' do
        it 'errors out' do
          stub_data_moves

          expect(GDK).to receive(:make).and_return(false)
          expect(GDK::Output).to receive(:error).with('Failed to reset data.')
          expect(GDK).not_to receive(:start).with([])
          expect(GDK).to receive(:display_help_message)

          subject.run
        end
      end

      context 'and make command succeeds also' do
        it 'resets data' do
          stub_data_moves

          expect(GDK).to receive(:make).and_return(true)
          expect(GDK::Output).to receive(:notice).with("Moving PostgreSQL data from '#{postgresql_data_directory}' to '#{new_postgresql_data_directory}'")
          expect(GDK::Output).to receive(:notice).with("Moving Rails uploads from '#{rails_uploads_directory}' to '#{new_rails_uploads_directory}'")
          expect(GDK::Output).to receive(:notice).with("Moving git repository data from '#{git_repository_data_directory}' to '#{new_git_repository_data_directory}'")
          expect(GDK::Output).to receive(:notice).with('Successfully reset data!')
          expect(GDK).to receive(:start).with([])

          subject.run
        end
      end
    end

    def expect_rename_success(directory, new_directory)
      expect(File).to receive(:rename).with(directory, new_directory).and_return(true)
    end

    def stub_data_moves
      stub_postgres_data_move
      expect_rename_success(postgresql_data_directory, new_postgresql_data_directory)

      stub_rails_uploads_move
      expect_rename_success(rails_uploads_directory, new_rails_uploads_directory)

      stub_git_repository_data_move
      expect_rename_success(git_repository_data_directory, new_git_repository_data_directory)
    end

    def stub_postgres_data_move
      allow(root).to receive(:join).with('postgresql/data').and_return(postgresql_data_directory)
      allow(root).to receive(:join).with("postgresql/data.#{current_timestamp}").and_return(new_postgresql_data_directory)
      allow(postgresql_data_directory).to receive(:exist?).and_return(true)
    end

    def stub_rails_uploads_move
      allow(root).to receive(:join).with('gitlab/public/uploads').and_return(rails_uploads_directory)
      allow(root).to receive(:join).with("gitlab/public/uploads.#{current_timestamp}").and_return(new_rails_uploads_directory)
      allow(rails_uploads_directory).to receive(:exist?).and_return(true)
    end

    def stub_git_repository_data_move
      allow(root).to receive(:join).with('repositories').and_return(git_repository_data_directory)
      allow(root).to receive(:join).with("repositories.#{current_timestamp}").and_return(new_git_repository_data_directory)

      allow(git_repository_data_directory).to receive(:exist?).and_return(true)

      git_restore_repositoriess_double = instance_double(Shellout, try_run: '', success?: true)
      expect(Shellout).to receive(:new).with('git restore repositories', chdir: root).and_return(git_restore_repositoriess_double)
    end
  end
end
