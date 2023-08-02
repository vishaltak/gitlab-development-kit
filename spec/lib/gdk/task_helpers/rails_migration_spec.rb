# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::TaskHelpers::RailsMigration, :hide_stdout do
  describe '#migrate' do
    let(:shellout_mock) { instance_double(Shellout, success?: true) }

    subject(:migrate) { described_class.new.migrate }

    before do
      allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      stub_pg_bindir
    end

    context 'database is not in recovery' do
      let(:timings) { '0.350000 0.400000  0.750000 (  0.80000)' }

      before do
        allow_any_instance_of(GDK::Postgresql).to receive(:in_recovery?).and_return(false)
      end

      context 'when asdf is available' do
        it "starts with 'asdf exec'" do
          allow(GDK.config).to receive_message_chain(:asdf, :__available?).and_return(true)

          expect(Shellout).to receive(:new).with(start_with('asdf', 'exec'), any_args).and_return(shellout_mock)

          migrate
        end
      end

      context 'when asdf is not available' do
        it "does not start with 'asdf exec'" do
          allow(GDK.config).to receive_message_chain(:asdf, :__available?).and_return(false)

          expect(Shellout).to receive(:new).with(array_including('bundle', 'exec'), any_args).and_return(shellout_mock)

          migrate
        end
      end

      it 'migrates the main database' do
        expect(Shellout).to receive(:new).with(array_including('db:migrate'), any_args).and_return(shellout_mock)

        migrate
      end

      it 'migrates the Geo database when Geo is enabled' do
        stub_gdk_yaml('geo' => { 'enabled' => true })

        expect(Shellout).to receive(:new).with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

        migrate
      end

      it 'does not migrate the main database when Geo is a secondary' do
        stub_gdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

        allow(Shellout).to receive(:new).and_return(shellout_mock)
        expect(Shellout).not_to receive(:new).with(array_including('db:migrate'), any_args)

        migrate
      end

      it 'finishes migration within the timeout' do
        allow(Timeout).to receive(:timeout).with(GDK::TaskHelpers::RailsMigration::MIGRATION_TIMEOUT).and_yield
        allow(Benchmark).to receive(:measure).and_return(timings)

        expect(GDK::Output).to receive(:notice).with("Migration finished. Timings:\n#{Benchmark::CAPTION} #{timings}")

        migrate
      end

      it 'exits when migration takes longer than the timeout' do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        expect(GDK::Output).to receive(:error).with('Migration took longer than 10 minutes and was terminated.')
        expect { migrate }.to raise_error(SystemExit)
      end
    end

    context 'database is in recovery' do
      before do
        allow_any_instance_of(GDK::Postgresql).to receive(:in_recovery?).and_return(true)
      end

      it 'does nothing' do
        expect(Shellout).not_to receive(:new)

        migrate
      end

      it 'migrates the Geo database when Geo is enabled' do
        stub_gdk_yaml('geo' => { 'enabled' => true })

        expect(Shellout).to receive(:new).with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

        migrate
      end
    end
  end
end
