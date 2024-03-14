# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::Redis do
  let(:tmp_path) { Dir.mktmpdir('gdk-path') }
  let(:pg_bin_dir) { tmp_path }
  let(:psql) { File.join(pg_bin_dir, 'redis') }

  describe '#success?' do
    let(:redis_success) { true }

    before do
      stub_redis_version('Redis server v=7.0.14 sha=00000000:0 malloc=libc bits=64 build=8c00cfe7cad4cc9', success: redis_success)
      stub_asdf_version('redis           7.0.14          /Users/maxwoolf/gitlab-development-kit/.tool-versions', success: true)
    end

    context 'versions testing' do
      context 'when redis-server matches asdf version' do
        it 'returns true' do
          expect(subject).to be_success
        end
      end

      context 'when redis-server does not match asdf version' do
        before do
          stub_redis_version('Redis server v=7.0.18 sha=00000000:0 malloc=libc bits=64 build=8c00cfe7cad4cc9', success: redis_success)
        end

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end
    end


    def stub_redis_version(result, success: true)
      stub_shellout(%W[redis-server --version], result, success: success)
    end

    def stub_asdf_version(result, success: true)
      stub_shellout(%W[asdf current], result, success: success)
    end

    def stub_shellout(command, result, success: true)
      shellout = instance_double(Shellout, read_stdout: result, success?: success)
      allow(Shellout).to receive(:new).with(command).and_return(shellout)
      allow(shellout).to receive(:execute).and_return(shellout)
    end
  end
end
