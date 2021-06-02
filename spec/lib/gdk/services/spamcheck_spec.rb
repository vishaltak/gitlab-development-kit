# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Spamcheck do
  describe '#name' do
    it 'returns spamcheck' do
      expect(subject.name).to eq('spamcheck')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run spamcheck' do
      expect(subject.command).to eq('')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end
end
