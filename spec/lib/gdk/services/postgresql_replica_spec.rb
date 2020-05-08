# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::PostgreSQLReplica do # rubocop:disable RSpec/FilePath
  describe '#name' do
    it 'return postgresql-replica' do
      expect(subject.name).to eq('postgresql-replica')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run PostgreSQL replica' do
      expect(subject.command).to eq("support/postgresql-signal-wrapper /usr/lib/postgresql/11/bin/postgres -D /home/git/gdk/postgresql-replica/data -k /home/git/gdk/postgresql-replica -h ''")
    end
  end

  describe '#enabled?' do
    it 'is disable by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
