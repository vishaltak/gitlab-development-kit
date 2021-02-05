# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::ResetData do
  let(:root) { GDK.root }
  let(:pg_data_path) { root.join('postgresql', 'data') }
  let(:uploads_path) { root.join('gitlab', 'public', 'uploads') }
  let(:repo_path) { root.join('repositories') }
  let(:data_dirs) { [pg_data_path, uploads_path, repo_path] }
  let(:backup_data_dirs) { data_dirs.map { |dir| "#{dir}.old" } }
  let(:content) { 'Foo' }

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
        expect(described_class).to_not receive(:new)

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
    let(:backup_script_shellout) { nil }

    before do
      allow(GDK).to receive(:remember!)
      allow(Runit).to receive(:stop)

      allow(Shellout).to receive(:new).with(root.join('support/backup-data').to_s, chdir: GDK.root).and_return(backup_script_shellout)
      allow(backup_script_shellout).to receive(:run).and_return(backup_script_shellout)
    end

    context 'when backup data script fails' do
      let(:backup_script_shellout) { instance_double(Shellout, 'success?': false) }

      it 'errors out', :hide_stdout do
        expect(GDK::Output).to receive(:error).with('Failed to backup data.')
        expect(GDK).to receive(:display_help_message)
        expect(GDK).to_not receive(:make)

        subject.run
      end
    end

    context 'when backup data script succeeds', :hide_stdout do
      let(:backup_script_shellout) { instance_double(Shellout, 'success?': true) }

      context 'but make command fails' do
        it 'errors out' do
          expect(GDK).to receive(:make).and_return(false)
          expect(GDK::Output).to receive(:error).with('Failed to reset data.')
          expect(GDK).to_not receive(:start).with([])
          expect(GDK).to receive(:display_help_message)

          subject.run
        end
      end

      context 'and make command succeeds also' do
        it 'resets data' do
          expect(GDK).to receive(:make).and_return(true)
          expect(GDK::Output).to receive(:notice).with('Successfully reset data!')
          expect(GDK).to receive(:start).with([])

          subject.run
        end
      end
    end
  end
end
