# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Services::RedisCluster do
  describe '#name' do
    it 'return redis' do
      expect(subject.name).to eq('redis-cluster')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run redis cluster' do
      expect(subject.command).to eq('support/redis-cluster-signal-wrapper 3 6000 /home/git/gdk/redis-cluster')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end
end
