# frozen_string_literal: true

require 'gdk/postgresql_upgrader'

RSpec.describe GDK::PostgresqlUpgrader do
  let(:target_version) { 14 }

  subject { described_class.new(target_version) }

  describe '#initialize' do
    it 'initializes with a target version' do
      expect(subject.instance_variable_get(:@target_version)).to eq(target_version)
    end
  end

  describe '#upgrade!' do
    before do
      allow(subject).to receive_messages(
        upgrade_needed?: true,
        current_version: 13,
        gdk_stop: true,
        init_db_in_target_path: true,
        rename_current_data_dir: true,
        pg_upgrade: true,
        promote_new_db: true,
        gdk_reconfigure: true,
        pg_replica_upgrade: true,
        rename_current_data_dir_back: true
      )
    end

    context 'with asdf' do
      let(:result) { "  13.12\n  13.9\n  14.8\n  14.9\n  15.1\n  15.2\n  15.3\n" }
      let(:version_list_double) { instance_double(Shellout, try_run: result) }

      before do
        allow(GDK::Dependencies).to receive_messages(asdf_available?: true, asdf_available_versions: [13, 14, 15])

        shellout_double = instance_double(Shellout, try_run: '', exit_code: 0)

        allow(Shellout).to receive(:new).with(anything).and_return(shellout_double)
        allow(Shellout).to receive(:new).with(%w[asdf list postgres]).and_return(version_list_double)
      end

      describe '#bin_path' do
        it 'returns latest version' do
          stub_env('ASDF_DATA_DIR', '/home/on/the/range/.asdf')

          expect(subject.bin_path).to eq('/home/on/the/range/.asdf/installs/postgres/14.9/bin')
        end
      end

      context 'when upgrade is needed' do
        it 'performs a successful upgrade' do
          expect { subject.upgrade! }.to output(/Upgraded/).to_stdout
        end
      end

      context 'when upgrade is not needed' do
        before do
          allow(subject).to receive(:upgrade_needed?).and_return(false)
        end

        it 'does not perform an upgrade' do
          expect { subject.upgrade! }.to output(/already compatible/).to_stdout
        end
      end
    end
  end
end
