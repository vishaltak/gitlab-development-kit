# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::PostgreSQL do # rubocop:disable RSpec/FilePath
  before do
    @tmp_file = stub_data_version(11)
  end

  after do
    FileUtils.rm(@tmp_file) if File.exist?(@tmp_file) # rubocop:todo RSpec/InstanceVariable
  end

  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    let(:psql_success) { true }

    before do
      stub_psql_version('psql (PostgreSQL) 11.9', success: psql_success)
    end

    context 'versions testing' do
      before do
        allow(subject).to receive(:can_create_postgres_socket?).and_return(true)
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

  def stub_psql_version(result, success: true)
    # rubocop:todo RSpec/VerifiedDoubles
    shellout = double('Shellout', try_run: result, read_stdout: result, success?: success)
    # rubocop:enable RSpec/VerifiedDoubles
    allow(Shellout).to receive(:new).with(%w[psql --version]).and_return(shellout)
    allow(shellout).to receive(:try_run).and_return(result)
  end
end
