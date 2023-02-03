# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::StaleServices do
  let(:stale_processes) do
    <<~STALE_PROCESSES
      95010 runsv rails-web
      95011 runsv rails-actioncable
    STALE_PROCESSES
  end

  describe '#success?' do
    before do
      stub_ps(output, exit_code: exit_code)
    end

    context 'but ps fails' do
      let(:exit_code) { 2 }

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end

    context 'and ps succeeds' do
      let(:exit_code) { nil }

      context 'and there are no stale processes' do
        let(:exit_code) { 1 }
        let(:output) { '' }

        it 'returns true' do
          expect(subject).to be_success
        end
      end

      context 'but there are stale processes' do
        let(:exit_code) { 0 }
        let(:output) { stale_processes }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end
    end
  end

  describe '#detail' do
    before do
      stub_ps(output, exit_code: exit_code)
    end

    context 'but ps fails' do
      let(:output) { nil }
      let(:exit_code) { 2 }

      it "return 'Unable to run 'ps' command." do
        expect(subject.detail).to eq("Unable to run '#{subject.send(:command)}'.")
      end
    end

    context 'and ps succeeds' do
      let(:exit_code) { nil }

      context 'and there are no stale processes' do
        let(:exit_code) { 1 }
        let(:output) { '' }

        it 'returns nil' do
          expect(subject.detail).to be_nil
        end
      end

      context 'but there are stale processes' do
        let(:exit_code) { 0 }
        let(:output) { stale_processes }

        it 'returns help message' do
          expect(subject.detail).to eq("The following GDK services appear to be stale:\n\nrails-web\nrails-actioncable\n\nYou can try killing them by running 'gdk kill' or:\n\n kill 95010 95011\n")
        end
      end
    end
  end

  def stub_ps(result, exit_code: true)
    shellout = instance_double(Shellout, read_stdout: result, exit_code: exit_code)
    full_command = %(pgrep -l -P 1 -f "runsv (elasticsearch|geo-cursor|gitaly|gitlab-docs|gitlab-k8s-agent|gitlab-pages|gitlab-ui|gitlab-workhorse|grafana|jaeger|mattermost|minio|nginx|openldap|postgresql|postgresql-geo|postgresql-replica|praefect|prometheus|rails-background-jobs|rails-web|redis|registry|runner|snowplow-micro|spamcheck|sshd|tunnel_|webpack|sleep)")
    allow(Shellout).to receive(:new).with(full_command).and_return(shellout)
    allow(shellout).to receive(:execute).and_return(shellout)
  end
end
