# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Clickhouse do
  describe '#client_cmd' do
    let(:config) do
      {
        'clickhouse' => {
          'bin' => '/tmp/clickhouse123',
          'tcp_port' => 9898
        }
      }
    end

    before do
      stub_gdk_yaml(config)
    end

    it 'specifies clickhouse client command based on configured bin path' do
      expect(subject.client_cmd).to include('/tmp/clickhouse123', 'client')
    end

    it 'includes --port flag pointing to configured flag' do
      expect(subject.client_cmd).to include('--port=9898')
    end
  end

  describe '#installed?' do
    it 'returns true when there is a file at location specified in bin config' do
      mock_installed

      expect(subject.installed?).to be_truthy
    end

    it 'returns false when binary cant be found' do
      mock_not_installed

      expect(subject.installed?).to be_falsey
    end
  end

  describe '#current_version' do
    it 'returns version when it is installed' do
      shellout_double = instance_double(Shellout)
      allow(shellout_double).to receive(:try_run).and_return('ClickHouse server version 22.1.2.3')

      mock_installed
      allow(Shellout).to receive(:new).with(GDK.config.clickhouse.bin.to_s, 'server', '--version').and_return(shellout_double)

      expect(subject.current_version).to eq('22.1.2.3')
    end

    it 'doesnt return anything if not installed' do
      mock_not_installed

      expect(subject.current_version).to be_nil
    end
  end

  def mock_installed
    allow(File).to receive(:exist?).with(GDK.config.clickhouse.bin).and_return(true)
  end

  def mock_not_installed
    allow(File).to receive(:exist?).with(GDK.config.clickhouse.bin).and_return(false)
  end
end
