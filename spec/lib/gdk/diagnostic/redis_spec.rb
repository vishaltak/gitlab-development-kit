# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::Redis do
  describe '#success?' do
    let(:redis_server_command_success) { true }

    before do
      stub_redis_server_version("Redis server v=1.2.3", success: redis_server_command_success)
      stub_redis_tool_version('1.2.3')
    end

    context 'when redis-server --version matches the version in .tool-versions' do
      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'when redis-server --version differs' do
      before do
        stub_redis_server_version("Redis server v=9.9.9", success: redis_server_command_success)
      end

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end

    context 'when redis-server --version fails' do
      let(:redis_server_command_success) { false }

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end
  end

  def stub_redis_server_version(result, success: true)
    stub_shellout('redis-server --version', result, success: success)
  end

  def stub_redis_tool_version(version)
    asdf_tool_versions = instance_double(Asdf::ToolVersions)

    allow(Asdf::ToolVersions).to receive(:new).and_return(asdf_tool_versions)
    allow(asdf_tool_versions).to receive(:default_version_for).with('redis').and_return(version)

    asdf_tool_versions
  end

  def stub_shellout(command, result, success: true)
    shellout_double = instance_double(Shellout, read_stdout: result, success?: success)

    allow(Shellout).to receive(:new).with(command).and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(display_output: false, display_error: false).and_return(shellout_double)
  end
end
