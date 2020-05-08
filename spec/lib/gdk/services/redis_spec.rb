# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Redis do
  describe '#name' do
    it 'return redis' do
      expect(subject.name).to eq('redis')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run redis' do
      expect(subject.command).to eq('redis-server /home/git/gdk/redis/redis.conf')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end
end
