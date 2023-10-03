# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::PostgreSQL do # rubocop:disable RSpec/FilePath
  before do
    @tmp_file = stub_data_version(11)
  end

  after do
    FileUtils.rm_f(@tmp_file) # rubocop:todo RSpec/InstanceVariable
  end

  describe '#success?' do
    let(:psql_success) { true }

    before do
      stub_psql_version('psql (PostgreSQL) 11.9', success: psql_success)
    end

    context 'versions testing' do
      before do
        allow(subject).to receive(:can_create_postgres_socket?).and_return(true)
        allow(subject).to receive(:valid_ldflags?).and_return(true)
      end

      context 'when psql --version matches PG_VERSION' do
        it 'returns true' do
          expect(subject).to be_success
        end
      end

      context 'when psql --version differs' do
        before do
          stub_psql_version('psql (PostgreSQL) 12.8', success: psql_success)
        end

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context 'when psql does not succeed' do
        let(:psql_success) { false }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context 'when psql --version is 9.6' do
        before do
          stub_psql_version('psql (PostgreSQL) 9.6.18', success: psql_success)
        end

        it 'returns false' do
          expect(subject).not_to be_success
        end

        context 'when data version is 9.6' do
          before do
            allow(subject).to receive(:data_dir_version).and_return(9.6)
          end

          it 'returns false' do
            expect(subject).to be_success
          end
        end
      end
    end

    context 'socket creation testing' do
      let(:can_create_socket) { nil }

      before do
        allow(subject).to receive(:versions_ok?).and_return(true)
        allow(subject).to receive(:valid_ldflags?).and_return(true)
        stub_can_create_socket.and_return(can_create_socket)
      end

      context 'when the GDK base directory length is too long' do
        let(:can_create_socket) { false }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context 'when the GDK base directory length is OK' do
        let(:can_create_socket) { true }

        it 'returns true' do
          expect(subject).to be_success
        end
      end
    end

    context 'ldflags testing' do
      let(:valid_ldflags) { nil }
      let(:pgvector_enabled) { nil }
      let(:isysroot_path) { '/Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk' }
      let(:isysroot_path_exists) { nil }
      let(:pg_config_ldflags) { "-isysroot #{isysroot_path}" }
      let(:xcrun_sdk_path) { '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk' }
      let(:realpath) { '/expected/isysroot_path' }

      before do
        allow(subject).to receive(:can_create_postgres_socket?).and_return(true)
        allow(subject).to receive(:data_dir_version).and_return(12)
        allow(subject).to receive(:versions_ok?).and_return(true)
        allow(subject).to receive(:macos?).and_return(true)

        allow_any_instance_of(GDK::Config).to receive_message_chain('pgvector.enabled').and_return(pgvector_enabled)

        stub_isysroot_path_exists?(isysroot_path, isysroot_path_exists)
        stub_pg_config_ldflags(pg_config_ldflags)
        stub_xcrun_sdk_path(xcrun_sdk_path)
        stub_realpath(isysroot_path, realpath)
        stub_realpath(xcrun_sdk_path, realpath)
      end

      context 'when pgvector is enabled' do
        let(:pgvector_enabled) { true }
        let(:isysroot_path_exists) { true }

        context 'when pg_config_ldflags includes -isysroot flag, and matches xcrun_sdk_path' do
          it 'returns true' do
            expect(subject).to be_success
          end
        end

        context 'when pg_config_ldflags includes -isysroot flag, but does not match xcrun_sdk_path' do
          let(:pg_config_ldflags) { '-isysroot /wrong/path' }
          let(:isysroot_path) { '/wrong/path' }
          let(:isysroot_path_exists) { false }

          it 'returns false' do
            expect(subject).not_to be_success
          end
        end

        context 'when pg_config_ldflags does not include -isysroot flag' do
          let(:pg_config_ldflags) { '-wrong-flag' }

          it 'returns false' do
            expect(subject).not_to be_success
          end
        end

        context 'when isysroot_path does not exist' do
          let(:isysroot_path_exists) { false }

          it 'returns false' do
            expect(subject).not_to be_success
          end
        end

        context 'when not on macOS' do
          before do
            allow(subject).to receive(:macos?).and_return(false)
          end

          it 'returns true' do
            expect(subject).to be_success
          end
        end

        context 'when comparing realpaths between isysroot_path and xcrun_sdk_path' do
          it 'returns false if realpaths do not match' do
            allow(File).to receive(:realpath).with(xcrun_sdk_path).and_return('/wrong/realpath')

            expect(subject).not_to be_success
          end
        end
      end

      context 'when pgvector is not enabled' do
        it 'returns true' do
          expect(subject).to be_success
        end
      end
    end
  end

  describe '#detail' do
    context 'when successful' do
      before do
        allow(subject).to receive(:success?).and_return(true)
      end

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end

    context 'versions testing' do
      before do
        allow(subject).to receive(:can_create_postgres_socket?).and_return(true)
        allow(subject).to receive(:valid_ldflags?).and_return(true)
      end

      context 'when unsuccessful' do
        before do
          allow(subject).to receive(:success?).and_return(false)
          allow(subject).to receive(:psql_version).and_return(11.8)
          allow(subject).to receive(:data_dir_version).and_return(12)
        end

        it 'returns help message' do
          expected = <<~MESSAGE
            `psql` is version 11.8, but your PostgreSQL data dir is using version 12.

            Check that your PATH is pointing to the right PostgreSQL version, or see the PostgreSQL upgrade guide:
            https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md#upgrade-postgresql
          MESSAGE

          expect(subject.detail).to eq(expected)
        end
      end
    end

    context 'socket creation testing' do
      before do
        allow(subject).to receive(:versions_ok?).and_return(true)
        allow(subject).to receive(:valid_ldflags?).and_return(true)
      end

      context 'when unsuccessful' do
        before do
          stub_can_create_socket.and_return(false)
        end

        it 'returns help message' do
          expected = <<~MESSAGE
            GDK directory's character length (13) is too long to support the creation
            of a UNIX socket for Postgres:

              /home/git/gdk

            Try using a shorter directory path for GDK or use TCP for Postgres.
          MESSAGE

          expect(subject.detail).to eq(expected)
        end
      end

      context 'ldflags testing' do
        before do
          allow(subject).to receive(:can_create_postgres_socket?).and_return(true)
          allow(subject).to receive(:data_dir_version).and_return(12)
          allow(subject).to receive(:versions_ok?).and_return(true)
        end

        context 'when unsuccessful' do
          let(:error_message) { 'The `-isysroot` value not present in `pg_config --ldflags`.' }

          before do
            allow(subject).to receive(:psql_version).and_return(14.9)
            allow(subject).to receive(:valid_ldflags?).and_return(false)
            subject.instance_variable_set(:@pgconfig_error, error_message)
          end

          it 'returns help message' do
            expected = <<~MESSAGE
              #{error_message}

              This may indicate a potential issue with the PostgreSQL installation, and we recommend reinstalling PostgreSQL.

              You can try running the following to reinstall PostgreSQL:

              asdf uninstall postgres 14.9 && asdf install postgres 14.9
            MESSAGE

            expect(subject.detail).to eq(expected)
          end
        end
      end

      context 'when unhandled' do
        before do
          stub_can_create_socket.and_raise(ArgumentError.new('something else'))
        end

        it 'returns help message' do
          expect { subject.detail }.to raise_error('something else')
        end
      end
    end
  end

  def stub_can_create_socket
    allow(subject).to receive(:can_create_socket?).with('/home/git/gdk/postgresql_.s.PGSQL.XXXXX')
  end

  def stub_data_version(version)
    tmpfile = Tempfile.new
    tmpfile.write(version)
    tmpfile.close
    allow(subject).to receive(:data_dir_version_filename).and_return(tmpfile.path)

    tmpfile.path
  end

  def stub_isysroot_path_exists?(isysroot_path, exists)
    allow(Dir).to receive(:exist?).with(isysroot_path).and_return(exists)
  end

  def stub_psql_version(result, success: true)
    stub_shellout(%w[psql --version], result, success: success)
  end

  def stub_pg_config_ldflags(result)
    stub_shellout('pg_config --ldflags', result)
  end

  def stub_realpath(path, realpath)
    allow(File).to receive(:realpath).with(path).and_return(realpath)
  end

  def stub_shellout(command, result, success: true)
    shellout = instance_double(Shellout, read_stdout: result, success?: success)
    allow(Shellout).to receive(:new).with(command).and_return(shellout)
    allow(shellout).to receive(:execute).and_return(shellout)
  end

  def stub_xcrun_sdk_path(result)
    stub_shellout('xcrun --show-sdk-path', result)
  end
end
