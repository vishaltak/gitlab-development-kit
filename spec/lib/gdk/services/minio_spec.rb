# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Minio do
  describe '#name' do
    it 'return minio' do
      expect(subject.name).to eq('minio')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run redis' do
      expect(subject.command).to eq('env MINIO_REGION=gdk MINIO_ACCESS_KEY=minio MINIO_SECRET_KEY=gdk-minio minio server -C minio/config --address "127.0.0.1:9000" --compat minio/data')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
