# frozen_string_literal: true

describe GDK::Services::Minio do
  subject(:minio_service) { described_class.new }

  describe '#name' do
    it 'return minio' do
      expect(minio_service.name).to eq('minio')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run redis' do
      expect(minio_service.command).to eq('minio server -C minio/config --address "127.0.0.1:9000" --compat minio/data')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(minio_service.enabled?).to be(false)
    end
  end

  describe '#initialize' do
    it 'has a valid env' do
      expect { minio_service }.not_to raise_error
    end
  end
end
