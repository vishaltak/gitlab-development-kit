# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Runit do
  describe 'ALL_DATA_ORIENTED_SERVICE_NAMES' do
    it 'returns all data service names only' do
      expect(described_class::ALL_DATA_ORIENTED_SERVICE_NAMES).to contain_exactly(*%w[minio openldap gitaly praefect redis postgresql-geo postgresql])
    end
  end

  context 'with stubbed services' do
    let(:data_service_names) { %w[praefect redis postgresql] }
    let(:non_data_service_names) { %w[gitlab-workhorse rails-background-jobs rails-web webpack] }

    before do
      stub_services
    end

    describe '.data_oriented_service_names' do
      subject(:data_oriented_service_names) { described_class.data_oriented_service_names }

      it 'returns data service names only' do
        expect(data_oriented_service_names).to contain_exactly(*data_service_names)
        expect(data_oriented_service_names).not_to include(*non_data_service_names)
      end
    end

    describe '.non_data_oriented_service_names' do
      subject(:non_data_oriented_service_names) { described_class.non_data_oriented_service_names }

      it 'returns non-data service names only' do
        expect(non_data_oriented_service_names).to contain_exactly(*non_data_service_names)
        expect(non_data_oriented_service_names).not_to include(*data_service_names)
      end
    end

    describe '.all_service_names' do
      subject(:all_service_names) { described_class.all_service_names }

      it 'returns all service names' do
        expect(all_service_names).to include(*data_service_names + non_data_service_names)
      end

      it 'excludes praefect-gitaly-* service names' do
        expect(all_service_names).not_to include('praefect-gitaly-0')
      end
    end

    describe '.start' do
      subject(:start) { described_class.start(start_args) }

      context 'with empty args array' do
        let(:start_args) { [] }

        it 'starts data services first and then non-data services last' do
          allow(described_class).to receive(:data_oriented_service_names).and_return(data_service_names)
          allow(described_class).to receive(:non_data_oriented_service_names).and_return(non_data_service_names)

          data_service_names.reverse_each do |service_name|
            expect(described_class).to receive(:sv).with('start', [service_name]).and_return(true).ordered
          end

          expect(described_class).to receive(:sv).with('start', non_data_service_names).and_return(true).ordered

          start
        end
      end

      context 'with args array' do
        let(:start_args) { data_service_names }

        it 'starts the requested services' do
          expect(described_class).to receive(:sv).with('start', data_service_names)

          start
        end
      end

      context 'with a string' do
        let(:start_args) { 'postgresql' }

        it 'starts the requested service' do
          expect(described_class).to receive(:sv).with('start', [start_args])

          start
        end
      end
    end

    describe '.stop' do
      subject(:stop) { described_class.stop }

      it 'stops all services', :hide_output do
        allow(described_class).to receive(:data_oriented_service_names).and_return(data_service_names)
        allow(described_class).to receive(:non_data_oriented_service_names).and_return(non_data_service_names)
        allow(described_class).to receive(:unload_runsvdir!)

        expect(described_class).to receive(:sv).with('force-stop', non_data_service_names).and_return(true).ordered

        data_service_names.each do |service_name|
          expect(described_class).to receive(:sv).with('force-stop', [service_name]).and_return(true).ordered
        end

        stop
      end
    end

    describe '.unload_runsvdir!' do
      subject(:unload_runsvdir!) { described_class.unload_runsvdir! }

      it 'send the HUP signal to the runsvdir PID' do
        pid = 99999999999

        allow(described_class).to receive(:runsvdir_pid).and_return(pid)

        expect(Process).to receive(:kill).with('HUP', pid)

        unload_runsvdir!
      end
    end
  end

  def stub_services
    stub_const('Runit::SERVICES_DIR', Pathname.new('/tmp/gdk/services'))
    stub_const('Runit::ALL_DATA_ORIENTED_SERVICE_NAMES', data_service_names)

    allow(described_class::SERVICES_DIR).to receive(:join).and_call_original

    children_doubles = (data_service_names + non_data_service_names).map do |service_name|
      pathname_double = instance_double(Pathname, basename: service_name, exist?: true, directory?: true)
      allow(described_class::SERVICES_DIR).to receive(:join).with(service_name).and_return(pathname_double)

      pathname_double
    end

    allow(Pathname).to receive(:new).and_call_original
    services_dir_double = instance_double(Pathname, children: children_doubles)
    allow(Pathname).to receive(:new).with(described_class::SERVICES_DIR).and_return(services_dir_double)
  end
end
