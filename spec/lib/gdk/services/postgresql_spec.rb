# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::PostgreSQL do # rubocop:disable RSpec/FilePath
  describe '#name' do
    it 'return postgresql' do
      expect(subject.name).to eq('postgresql')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run PostgreSQL' do
      expect(subject.command).to eq("support/postgresql-signal-wrapper /usr/local/bin/postgres -D /home/git/gdk/postgresql/data -k /home/git/gdk/postgresql -h ")
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end
end
