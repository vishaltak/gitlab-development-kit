# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::Redis do
  describe '#success?' do
    context 'when redis-server version matches asdf redis version' do
      it 'returns true' do
        stub_good_redis_server_version

        expect(subject).to be_success
      end
    end

    context "when redis-server version doesn't match asdf redis version" do
      it 'returns false' do
        stub_bad_redis_server_version

        expect(subject).not_to be_success
      end
    end
  end

  describe '#detail' do
    context 'when redis-server version matches asdf redis version' do
      it 'returns nil' do
        stub_good_redis_server_version

        expect(subject.detail).to be_nil
      end
    end

    context "when redis-server version doesn't match asdf redis version" do
      it 'returns informational text' do
        stub_bad_redis_server_version

        expect(subject.detail).to eq(%(Redis version 9.9.9 does not match the expected version 7.0.14 in .tool-versions.\n\nPlease check your `PATH` for Redis with `which redis-server`. You can update your PATH to point to the correct version if necessary.\n))
      end
    end
  end

  def stub_good_redis_server_version
    stub_redis_server_version('Redis server v=7.0.14 sha=')
  end

  def stub_bad_redis_server_version
    stub_redis_server_version('Redis server v=9.9.9 sha=')
  end

  def stub_redis_server_version(result, success: true)
    stub_shellout('redis-server --version', result, success: success)
  end

  def stub_shellout(command, result, success: true)
    shellout = instance_double(Shellout, read_stdout: result, success?: success)
    allow(Shellout).to receive(:new).with(command).and_return(shellout)
    allow(shellout).to receive(:execute).and_return(shellout)
  end
end
