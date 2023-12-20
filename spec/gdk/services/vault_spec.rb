# frozen_string_literal: true

RSpec.describe GDK::Services::Vault do
  describe '#name' do
    it 'returns vault' do
      expect(subject.name).to eq('vault')
    end
  end

  describe '#command' do
    it 'returns command based on config' do
      expect(subject.command).to match(/vault server --dev --dev-listen-address=127.0.0.1:8200/)
    end
  end

  describe '#enabled?' do
    it 'returns true if set `enabled: true` in the config file' do
      config = {
        'vault' => {
          'enabled' => true
        }
      }

      stub_gdk_yaml(config)

      expect(subject.enabled?).to be(true)
    end

    it 'returns false if set `enabled: false` in the config file' do
      config = {
        'vault' => {
          'enabled' => false
        }
      }

      stub_gdk_yaml(config)

      expect(subject.enabled?).to be(false)
    end
  end
end
