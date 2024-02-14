# frozen_string_literal: true

require_relative '../../../support/gitlab-remote-development/setup_workspace'

describe SetupWorkspace do
  let(:duration) { 10 }
  let(:success) { true }
  let(:username) { 'remote' }

  let(:workspace) { described_class.new }

  before do
    allow(Process).to receive(:clock_gettime).and_return(0, duration)
    allow(Dir).to receive(:chdir).with(SetupWorkspace::ROOT_DIR).and_yield
    allow(workspace).to receive(:system).with('support/gitlab-remote-development/remote-development-gdk-bootstrap.sh').and_return(success)

    allow(workspace).to receive(:execute_bootstrap).and_return([success, duration])
    allow($stdin).to receive(:gets).and_return('yes')

    allow(GDK.config).to receive(:bury!).with('telemetry.username', username)
    allow(GDK.config).to receive(:save_yaml!)
    allow(GDK::Telemetry).to receive(:send_telemetry)
  end

  describe '#run', :hide_output do
    context 'when GDK setup flag file does not exist' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(SetupWorkspace::GDK_SETUP_FLAG_FILE).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:touch)
      end

      it 'executes the bootstrap script and creates GDK setup flag file' do
        expect(workspace).to receive(:execute_bootstrap)
        expect(FileUtils).to receive(:touch).with(SetupWorkspace::GDK_SETUP_FLAG_FILE)

        workspace.run
      end

      context 'when telemetry is allowed' do
        it 'sends telemetry' do
          expect(workspace).to receive(:send_telemetry).with(success, duration)

          workspace.run
        end
      end

      context 'when telemetry is not allowed' do
        before do
          allow($stdin).to receive(:gets).and_return('no')
        end

        it 'does not send telemetry' do
          expect(workspace).not_to receive(:send_telemetry)

          workspace.run
        end
      end
    end

    context 'when GDK setup flag file exists' do
      before do
        allow(File).to receive(:exist?).with(SetupWorkspace::GDK_SETUP_FLAG_FILE).and_return(true)
      end

      it 'does not execute the bootstrap script and outputs information about GDK is already being bootstrapped' do
        expect(workspace).not_to receive(:execute_bootstrap)
        expect(GDK::Output).to receive(:info).with("#{SetupWorkspace::GDK_SETUP_FLAG_FILE} exists, GDK has already been bootstrapped.\n\nRemove the #{SetupWorkspace::GDK_SETUP_FLAG_FILE} to re-bootstrap.")

        workspace.run
      end
    end
  end
end
