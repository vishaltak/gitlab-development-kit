# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Toxiproxy do
  describe '#name' do
    it 'return toxiproxy' do
      expect(subject.name).to eq('toxiproxy')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run toxiproxy' do
      expect(subject.command).to eq('env toxiproxy-server -host 127.0.0.1 -port 8474')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
