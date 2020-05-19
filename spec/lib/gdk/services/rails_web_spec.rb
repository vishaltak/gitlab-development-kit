# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::RailsWeb do
  describe '#name' do
    it 'return rails-web' do
      expect(subject.name).to eq('rails-web')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run Rails web' do
      expect(subject.command).to eq('/usr/bin/env RAILS_ENV=development RAILS_RELATIVE_URL_ROOT=/ support/exec-cd gitlab bin/web start_foreground')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end
end
