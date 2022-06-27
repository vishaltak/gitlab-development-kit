# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::GitLabWorkhorse do # rubocop:disable RSpec/FilePath
  describe '#name' do
    it 'return gitlab-workhorse' do
      expect(subject.name).to eq('gitlab-workhorse')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run GitLab Workhorse' do
      expect(subject.command).to eq('/usr/bin/env PATH="/home/git/gdk/gitlab/workhorse:$PATH" GEO_SECONDARY_PROXY=0 ' \
                                    'gitlab-workhorse -authSocket "/home/git/gdk/gitlab.socket" ' \
                                    '-documentRoot "/home/git/gdk/gitlab/public" ' \
                                    '-developmentMode -secretPath "/home/git/gdk/gitlab/.gitlab_workhorse_secret" ' \
                                    '-config "/home/git/gdk/gitlab/workhorse/config.toml" ' \
                                    '-listenAddr "127.0.0.1:3000" -logFormat json')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end
end
