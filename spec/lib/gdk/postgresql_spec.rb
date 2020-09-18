# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe GDK::Postgresql do
  let(:yaml) { {} }
  let(:shellout_mock) { double('Shellout', run: nil, run!: nil, try_run: '', success?: true) }

  before do
    stub_pg_bindir
    stub_gdk_yaml(yaml)
  end

  describe '#use_tcp?' do
    context 'with host defined to a path' do
      let(:yaml) do
        {
          'postgresql' => {
            'host' => '/home/git/gdk/postgresql'
          }
        }
      end

      it 'returns false' do
        expect(subject).not_to be_use_tcp
      end
    end

    context 'with host defined to a hostname' do
      let(:yaml) do
        {
          'postgresql' => {
            'host' => 'localhost'
          }
        }
      end

      it 'returns true' do
        expect(subject).to be_use_tcp
      end
    end
  end

  describe '#db_exists?' do
    it 'calls psql with the correct arguments' do
      expect(Shellout).to receive(:new).with(array_including('/usr/local/bin/psql', '--dbname=blaat'), any_args).and_return(shellout_mock)

      expect(subject.db_exists?('blaat')).to be_truthy
    end
  end

  describe '#initdb' do
    it 'calls initdb' do
      expect(Shellout).to receive(:new).with(array_including('/usr/local/bin/initdb', GDK.config.postgresql.data_dir.to_s)).and_return(shellout_mock)

      subject.initdb
    end
  end

  describe '#createdb' do
    it 'calls createdb' do
      expect(Shellout).to receive(:new).with(array_including('/usr/local/bin/createdb', 'blaat'), any_args).and_return(shellout_mock)

      subject.createdb('blaat')
    end
  end

  describe '#in_recovery?' do
    it 'queries pg_is_in_recovery()' do
      expect(Shellout).to receive(:new).with(array_including('/usr/local/bin/psql', '--command=SELECT pg_is_in_recovery();'), any_args).and_return(shellout_mock)

      subject.in_recovery?
    end

    it 'returns true when psql query returned true' do
      expect(shellout_mock).to receive(:try_run).and_return('t')
      expect(Shellout).to receive(:new).and_return(shellout_mock)

      expect(subject).to be_in_recovery
    end

    it 'returns false when psql query returned false' do
      expect(shellout_mock).to receive(:try_run).and_return('f')
      expect(Shellout).to receive(:new).and_return(shellout_mock)

      expect(subject).not_to be_in_recovery
    end

    it 'returns false when psql failed' do
      expect(shellout_mock).to receive(:try_run).and_return('error: could not connect to server')
      expect(Shellout).to receive(:new).and_return(shellout_mock)

      expect(subject).not_to be_in_recovery
    end
  end

  describe '#trust_replication' do
    let(:tmpdir) { Pathname.new(Dir.mktmpdir) }
    let(:yaml) do
      {
        'postgresql' => {
          'data_dir' => tmpdir
        }
      }
    end

    it 'adds line to pg_hba.conf' do
      subject.trust_replication

      expect(tmpdir.join('pg_hba.conf').read).to match(/local\s+replication\s+gitlab_replication\s+trust/)
    end
  end

  describe '#standby_mode' do
    let(:tmpdir) { Pathname.new(Dir.mktmpdir) }
    let(:yaml) do
      {
        'postgresql' => {
          'data_dir' => tmpdir
        }
      }
    end

    it 'creates standby.signal if PostgreSQL version is 12' do
      stub_pg_version(12)

      subject.standby_mode

      expect(Pathname.new(tmpdir).join('standby.signal')).to exist
    end

    it 'does nothing if PostgreSQL version is 11' do
      stub_pg_version(11)

      subject.standby_mode

      expect(Pathname.new(tmpdir).join('standby.signal')).not_to exist
    end
  end

  describe '#query' do
    it 'runs query through psql' do
      expect(Shellout).to receive(:new).with(array_including('/usr/local/bin/psql', '--command=SELECT 1;')).and_return(shellout_mock)

      subject.query('SELECT 1;')
    end
  end

  describe '#reconfigure' do
    let(:tmpdir) { Pathname.new(Dir.mktmpdir) }
    let(:yaml) do
      {
        'postgresql' => {
          'data_dir' => tmpdir
        }
      }
    end

    it 'add incorrect includes to postgresql.conf' do
      stub_erb_renderer
      stub_pg_version(12)

      conf_file = tmpdir.join('postgresql.conf')

      conf_file.write(<<~CONF)
        port = 5432
        include 'gitlab.conf'
        include 'replication.conf'
      CONF

      subject.reconfigure

      expect(conf_file.read).to eq(<<~OUT)
        port = 5432
        include 'gdk.conf'
      OUT
    end

    it 'removes the old style include files' do
      stub_erb_renderer
      stub_line_in_file
      stub_pg_version(12)

      gitlab_conf = tmpdir.join('gitlab.conf').tap { |f| f.write('') }
      replication_conf = tmpdir.join('replication.conf').tap { |f| f.write('') }

      subject.reconfigure

      expect(gitlab_conf).not_to exist
      expect(replication_conf).not_to exist
    end

    context 'postgresql.port set to 54321' do
      let(:yaml) do
        {
          'postgresql' => {
            'data_dir' => tmpdir,
            'port' => '54321'
          }
        }
      end

      it 'renders gdk.conf with correct port' do
        stub_line_in_file
        stub_pg_version(12)

        subject.reconfigure

        gdk_conf = tmpdir.join('gdk.conf').readlines(chomp: true)

        expect(gdk_conf).to include('port = 54321')
      end
    end

    context 'geo secondary' do
      let(:yaml) do
        {
          'geo' => {
            'enabled' => true,
            'secondary' => true
          },
          'postgresql' => {
            'data_dir' => tmpdir
          }
        }
      end

      it 'renders gdk.conf with primary connection info when using PostgreSQL v12' do
        stub_pg_version(12)
        stub_line_in_file
        primary_mock = double('PrimaryConfig', host: 'bla', port: 5433)
        allow(subject).to receive(:primary_config).and_return(primary_mock)

        subject.reconfigure

        gdk_conf = tmpdir.join('gdk.conf').readlines(chomp: true)

        expect(gdk_conf).to include("primary_conninfo = 'host=bla port=5433 user=gitlab_replication'")
        expect(gdk_conf).to include("primary_slot_name = 'gitlab_gdk_replication_slot'")

        expect(tmpdir.join('recovery.conf')).not_to exist
      end

      it 'renders recovery.conf with primary connection info when using PostgreSQL v11' do
        stub_pg_version(11)
        stub_line_in_file
        primary_mock = double('PrimaryConfig', host: 'bla', port: 5433)
        allow(subject).to receive(:primary_config).and_return(primary_mock)

        subject.reconfigure

        recovery_conf = tmpdir.join('recovery.conf').readlines(chomp: true)

        expect(recovery_conf).to include("primary_conninfo = 'host=bla port=5433 user=gitlab_replication'")
        expect(recovery_conf).to include("primary_slot_name = 'gitlab_gdk_replication_slot'")
      end
    end
  end

  describe '#version' do
    it 'parses the version' do
      expect(shellout_mock).to receive(:try_run).and_return('psql (PostgreSQL) 12.4')
      expect(Shellout).to receive(:new).and_return(shellout_mock)

      expect(subject.version).to eq(12)
    end
  end

  def stub_pg_version(version)
    allow(subject).to receive(:version) { version }
  end

  def stub_erb_renderer
    mock = double('GDK::ErbRenderer', render!: nil)

    allow(GDK::ErbRenderer).to receive(:new).and_return(mock)
  end

  def stub_line_in_file
    mock = double('GDK::LineInFile', remove: nil, append: nil)

    allow(GDK::LineInFile).to receive(:new).and_return(mock)
  end
end
