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
      subject(:start) { described_class.start(services, **args) }

      shared_examples 'starts services' do |quiet|
        context 'with empty args array' do
          let(:services) { [] }

          it 'starts data services first and then non-data services last' do
            allow(described_class).to receive(:data_oriented_service_names).and_return(data_service_names)
            allow(described_class).to receive(:non_data_oriented_service_names).and_return(non_data_service_names)

            data_service_names.reverse_each do |service_name|
              expect(described_class).to receive(:sv).with('start', [service_name], quiet: quiet).and_return(true).ordered
            end

            expect(described_class).to receive(:sv).with('start', non_data_service_names, quiet: quiet).and_return(true).ordered

            start
          end
        end

        context 'with args array' do
          let(:services) { data_service_names }

          it 'starts the requested services' do
            expect(described_class).to receive(:sv).with('start', data_service_names, quiet: quiet)

            start
          end
        end

        context 'with a string' do
          let(:services) { 'postgresql' }

          it 'starts the requested service' do
            expect(described_class).to receive(:sv).with('start', [services], quiet: quiet)

            start
          end
        end
      end

      context 'with default operation' do
        it_behaves_like 'starts services', false do
          let(:args) { {} }
        end
      end

      context 'with quiet operation' do
        it_behaves_like 'starts services', true do
          let(:args) { { quiet: true } }
        end
      end
    end

    describe '.stop' do
      subject(:stop) { described_class.stop(**args) }

      shared_examples 'stops all services' do |quiet|
        it 'stops all services', :hide_output do
          allow(described_class).to receive(:data_oriented_service_names).and_return(data_service_names)
          allow(described_class).to receive(:non_data_oriented_service_names).and_return(non_data_service_names)
          allow(described_class).to receive(:unload_runsvdir!)

          expect(described_class).to receive(:sv).with('force-stop', non_data_service_names, quiet: quiet).and_return(true).ordered

          data_service_names.each do |service_name|
            expect(described_class).to receive(:sv).with('force-stop', [service_name], quiet: quiet).and_return(true).ordered
          end

          stop
        end
      end

      context 'with default operation' do
        it_behaves_like 'stops all services', false do
          let(:args) { {} }
        end
      end

      context 'with quiet operation' do
        it_behaves_like 'stops all services', true do
          let(:args) { { quiet: true } }
        end
      end
    end

    describe '.sv' do
      subject(:sv) { described_class.sv(command, services, **args) }

      let(:command) { 'stop' }
      let(:services) { data_service_names }
      let(:args) { {} }

      it 'sends the command to services' do
        expect(described_class).to receive(:start_runsvdir).and_return(nil)
        expect(described_class).to receive(:ensure_services_are_supervised)

        shellout_double2 = instance_double(Shellout, run: '', stream: '', success?: true)
        expect(Shellout).to receive(:new).with(%w[sv -w 20 stop /tmp/gdk/services/postgresql /tmp/gdk/services/praefect /tmp/gdk/services/redis], chdir: GDK.root).and_return(shellout_double2)

        expect(sv).to be_truthy
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

    describe '.tail' do
      subject(:tail) { described_class.tail(services) }

      let(:services) { %w[postgresql redis] }

      context 'when there are no logs to tail' do
        it 'returns true' do
          allow(described_class).to receive(:log_files).and_return([])

          expect(GDK::Output).to receive(:warn).with('There are no services to tail.')

          expect(tail).to be_truthy
        end
      end

      context 'when there are logs to tail' do
        it 'attempts to tail service log files' do
          stub_const('Runit::LOG_DIR', Pathname.new('/home/git/gdk/log'))

          expect(described_class).to receive(:exec).with('tail', '-qF', '/home/git/gdk/log/postgresql/current', '/home/git/gdk/log/redis/current')

          tail
        end
      end
    end
  end

  def stub_services
    stub_const('Runit::SERVICES_DIR', Pathname.new('/tmp/gdk/services'))
    stub_const('Runit::ALL_DATA_ORIENTED_SERVICE_NAMES', data_service_names)

    allow(described_class::SERVICES_DIR).to receive(:join).and_call_original
    allow(described_class::SERVICES_DIR).to receive(:exist?).and_return(true)

    children_doubles = (data_service_names + non_data_service_names).map do |service_name|
      pathname_double = Pathname.new(described_class::SERVICES_DIR.join(service_name))
      allow(pathname_double).to receive(:exist?).and_return(true)
      allow(pathname_double).to receive(:directory?).and_return(true)
      allow(described_class::SERVICES_DIR).to receive(:join).with(service_name).and_return(pathname_double)

      pathname_double
    end

    allow(Pathname).to receive(:new).and_call_original
    services_dir_double = instance_double(Pathname, children: children_doubles)
    allow(Pathname).to receive(:new).with(described_class::SERVICES_DIR).and_return(services_dir_double)
  end
end
