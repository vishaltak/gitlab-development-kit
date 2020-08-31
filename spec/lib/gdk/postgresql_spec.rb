# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Postgresql do
  let(:yaml) { {} }
  let(:shellout_mock) { double('Shellout', run: nil, try_run: '', success?: true) }

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
end
