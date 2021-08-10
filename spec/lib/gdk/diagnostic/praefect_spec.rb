# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Praefect do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'focusing on checking dir length' do
      before do
        allow(subject).to receive(:migrations_ok?).and_return(true)
      end

      context 'when the praefect internal socket dir length is >= the max' do
        it 'returns false' do
          stub_max_praefect_internal_socket_dir_length(1)

          expect(subject.success?).to be_falsey
        end
      end

      context 'when the praefect internal socket dir length is < the max' do
        it 'returns true' do
          stub_max_praefect_internal_socket_dir_length(999)

          expect(subject.success?).to be_truthy
        end
      end
    end

    context 'focusing on checking DB migrations' do
      before do
        allow(subject).to receive(:dir_length_ok?).and_return(true)
      end

      context 'when there are DB migrations that need attention' do
        it 'returns false' do
          stub_unmigrated_migration

          expect(subject.success?).to be_falsey
        end
      end

      context 'when there are no DB migrations that need attention' do
        it 'returns true' do
          stub_migrated_migration

          expect(subject.success?).to be_truthy
        end
      end
    end
  end

  describe '#detail' do
    context 'focusing on checking dir length' do
      before do
        allow(subject).to receive(:migrations_ok?).and_return(true)
      end

      context 'when the praefect internal socket dir length is >= the max' do
        it 'returns detail content' do
          stub_max_praefect_internal_socket_dir_length(1)

          expect(subject.detail).to match(/please try and reduce the directory depth/)
        end
      end

      context 'when the praefect internal socket dir length is < the max' do
        it 'returns nil' do
          stub_max_praefect_internal_socket_dir_length(999)

          expect(subject.detail).to be_nil
        end
      end
    end

    context 'focusing on checking DB migrations' do
      before do
        allow(subject).to receive(:dir_length_ok?).and_return(true)
      end

      context 'when there are DB migrations that need attention' do
        it 'returns detail content' do
          stub_unmigrated_migration

          expect(subject.detail).to match(/The following praefect DB migrations don't appear to have been applied/)
        end
      end

      context 'when there are no DB migrations that need attention' do
        it 'returns nil' do
          stub_migrated_migration

          expect(subject.detail).to be_nil
        end
      end
    end
  end

  def stub_max_praefect_internal_socket_dir_length(value)
    stub_const('GDK::Diagnostic::Praefect::MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH', value)
  end

  def stub_unmigrated_migration
    stub_db_migrations('20210525173505_valid_primaries_view', 'no')
  end

  def stub_migrated_migration
    stub_db_migrations('20210525173505_valid_primaries_view', '2021-07-12 17:03:00.155292 +1000 AEST')
  end

  def stub_db_migrations(migration, status)
    line = "| #{migration} | #{status} |"

    command = '/home/git/gdk/gitaly/_build/bin/praefect -config /home/git/gdk/gitaly/praefect.config.toml sql-migrate-status'
    shellout_double = instance_double('Shellout', readlines: [line])
    allow(Shellout).to receive(:new).with(command).and_return(shellout_double)
  end
end
