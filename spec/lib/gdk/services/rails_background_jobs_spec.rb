# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::RailsBackgroundJobs do
  describe '#name' do
    it 'return rails-background-jobs' do
      expect(subject.name).to eq('rails-background-jobs')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run GitLab Rails background jobs' do
      expect(subject.command).to eq('/usr/bin/env SIDEKIQ_LOG_ARGUMENTS=1 SIDEKIQ_WORKERS=1 RAILS_ENV=development RAILS_RELATIVE_URL_ROOT=/ support/exec-cd gitlab bin/background_jobs start_foreground')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end
end
