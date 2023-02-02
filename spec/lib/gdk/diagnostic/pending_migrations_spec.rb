# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::PendingMigrations do
  describe '#diagnose' do
    it 'is a no-op' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'when there are pending DB migrations' do
      it 'returns false' do
        stub_pending_migrations(false)

        expect(subject).not_to be_success
      end
    end

    context 'where there are no pending DB migrations' do
      it 'returns true' do
        stub_pending_migrations(true)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when there are pending DB migrations' do
      it 'returns a message' do
        stub_pending_migrations(false)

        expect(subject.detail).to match(/There are pending database migrations/)
      end
    end

    context 'where there are no pending DB migrations' do
      it 'returns no message' do
        stub_pending_migrations(true)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_pending_migrations(success)
    shellout_double = instance_double(Shellout, success?: success)
    cmd = %w[../support/bundle-exec rails db:abort_if_pending_migrations]

    allow(Shellout).to receive(:new).with(cmd, chdir: '/home/git/gdk/gitlab').and_return(shellout_double)
    allow(shellout_double).to receive(:execute).and_return(shellout_double)

    shellout_double
  end
end
