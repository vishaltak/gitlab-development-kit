require 'spec_helper'

describe GDK::ConfigSettings do
  class TestConfigSettings < GDK::ConfigSettings
    FILE = 'tmp/foo.yml'

    bar false
  end

  subject(:config) { TestConfigSettings.new }

  describe 'dynamic setting' do
    it 'can read a setting' do
      expect(config.bar).to eq(false)
    end

    context 'with foo.yml' do
      before do
        File.write(temp_path.join('foo.yml'), { 'bar' => 'baz' }.to_yaml)
      end

      after do
        File.unlink(temp_path.join('foo.yml'))
      end

      it 'reads settings from yaml' do
        expect(config.bar).to eq('baz')
      end
    end
  end

  describe '#array!' do
    it 'creates an array of the desired number of configs' do
      expect(config.config_array!(3, &:nil).count).to eq(3)
    end

    it 'creates configs with self as parent' do
      expect(config.config_array!(1, &:nil).first.parent).to eq(config)
    end

    it 'attributes are available through root config' do
      config = Class.new(GDK::ConfigSettings) do
        array do
          config_array!(3) do |sub, idx|
            sub.buz { "sub #{idx}" }
          end
        end
      end.new

      expect(config.array.first.buz).to eq('sub 0')
    end
  end

  describe '#read!' do
    before do
      expect(GDK).to receive(:root) { fixture_path }
    end

    it 'can read a setting from a file' do
      expect(config.read!('port_file')).to eq(1234)
    end

    context 'when a deprecation message is present' do
      it 'does nothing when setting file is not found or empty' do
        fetch_config = -> { config.read!('non_existent', deprecation_message: 'nothing') }

        expect(fetch_config.call).to be_nil
        expect { fetch_config.call }.to_not output.to_stdout
      end
    end
  end
end
