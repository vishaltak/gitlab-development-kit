# frozen_string_literal: true

describe GDK::Services::Vault do
  describe '#name' do
    it 'returns vault' do
      expect(subject.name).to eq('vault')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run vault' do
      expect(subject.command).to eq('/usr/local/bin/vault server --dev --dev-listen-address=127.0.0.1:8200')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
