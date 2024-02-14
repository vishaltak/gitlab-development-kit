# frozen_string_literal: true

require_relative '../../../support/gitlab-remote-development/setup_workspace'

describe SetupWorkspace do
  let(:duration) { 10 }
  let(:success) { true }
  let(:username) { 'testuser' }

  let(:workspace) { described_class.new }

  before do
    allow(Process).to receive(:clock_gettime).and_return(0, duration)
    allow(Dir).to receive(:chdir).with(SetupWorkspace::ROOT_DIR).and_yield
    allow(workspace).to receive(:system).with('support/gitlab-remote-development/remote-development-gdk-bootstrap.sh').and_return(success)

    allow(workspace).to receive(:execute_bootstrap).and_return([success, duration])
    allow($stdin).to receive(:gets).and_return('yes')

    allow(GDK::Config).to receive(:bury!).with('telemetry.username', username)
    allow(GDK::Config).to receive(:save_yaml!)
    allow(GDK::Telemetry).to receive(:send_telemetry)
  end

  describe '#run', :hide_output do
    context 'when bootstrap is needed' do
      before do
        allow(workspace).to receive(:bootstrap_needed?).and_return(true)
      end

      context 'when telemetry is allowed' do
        it 'executes the bootstrap script and sends telemetry' do
          expect(workspace).to receive(:execute_bootstrap)
          expect(workspace).to receive(:send_telemetry).with(success, duration)

          workspace.run
        end
      end

      context 'when telemetry is not allowed' do
        before do
          allow($stdin).to receive(:gets).and_return('no')
        end

        it 'executes the bootstrap script but does not send telemetry' do
          expect(workspace).to receive(:execute_bootstrap)
          expect(workspace).not_to receive(:send_telemetry)

          workspace.run
        end
      end
    end

    context 'when bootstrap is not needed' do
      before do
        allow(workspace).to receive(:bootstrap_needed?).and_return(false)
      end

      it 'does not execute the bootstrap script and outputs information about GDK is already being bootstrapped' do
        expect(workspace).not_to receive(:execute_bootstrap)
        expect(GDK::Output).to receive(:info).with("#{SetupWorkspace::GDK_BOOTSTRAPPED_FILE} exists, GDK has already been bootstrapped.\n\nRemove the #{SetupWorkspace::GDK_BOOTSTRAPPED_FILE} to re-bootstrap.")

        workspace.run
      end
    end
  end
end
