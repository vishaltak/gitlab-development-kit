# frozen_string_literal: true

require 'gdk/postgresql_upgrader'

RSpec.describe GDK::PostgresqlUpgrader do
  let(:tmp_path) { Pathname.new(Dir.mktmpdir('gdk-path')) }
  let(:running_version) { 13 }
  let(:target_version) { 14 }
  let(:available_versions) do
    { 14 => tmp_path.join('14/bin').to_s, 13 => tmp_path.join('13/bin').to_s }
  end

  subject { described_class.new(running_version: running_version, target_version: target_version) }

  before do
    allow_any_instance_of(GDK::Dependencies::PostgreSQL::Binaries).to receive(:available_versions)
      .and_return(available_versions)
    allow(subject.send(:postgresql)).to receive(:current_version).and_return(running_version)
  end

  describe '#initialize' do
    it 'initializes with a target version' do
      expect(subject.instance_variable_get(:@target_version)).to eq(target_version)
    end
  end

  describe '#upgrade!' do
    before do
      allow(subject).to receive(:run_gdk!).with('stop').and_return(true)
      allow(subject).to receive_messages(
        init_db_in_target_path: true,
        rename_current_data_dir: true,
        pg_upgrade: true,
        promote_new_db: true
      )
      allow(subject).to receive(:run_gdk!).with('reconfigure').and_return(true)
      allow(subject).to receive_messages(
        pg_replica_upgrade: true,
        rename_current_data_dir_back: true
      )
    end

    context 'with asdf' do
      before do
        allow(GDK::Dependencies).to receive_messages(
          asdf_available?: true,
          asdf_available_versions: [13, 14, 15]
        )
      end

      context 'when upgrade is needed' do
        it 'performs a successful upgrade' do
          expect { subject.upgrade! }.to output(/Upgraded/).to_stdout
        end
      end

      context 'when upgrade is not needed' do
        let(:running_version) { target_version }

        it 'does not perform an upgrade' do
          expect { subject.upgrade! }.to output(/already compatible/).to_stdout
        end
      end
    end
  end
end
