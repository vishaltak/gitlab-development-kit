# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::RubyGems do
  let(:allow_gem_not_installed) { nil }

  subject(:diagnostic) { described_class.new(allow_gem_not_installed: allow_gem_not_installed) }

  before do
    stub_const('GDK::Diagnostic::RubyGems::GITLAB_GEMS_WITH_C_CODE_TO_CHECK', %w[bad_gem])
  end

  describe '#success?' do
    before do
      stub_gem_installed('bad_gem', gem_installed)
    end

    context 'when bad_gem is not installed' do
      let(:gem_installed) { false }

      context 'and allow_gem_not_installed is false' do
        let(:allow_gem_not_installed) { false }

        it { is_expected.not_to be_success }
      end

      context 'and allow_gem_not_installed is true' do
        let(:allow_gem_not_installed) { true }

        it { is_expected.to be_success }
      end
    end

    context 'when bad_gem is installed' do
      let(:gem_installed) { true }

      before do
        stub_gem_loads_ok('bad_gem', gem_loads_ok)
      end

      context 'and bad_gem cannot be loaded' do
        let(:gem_loads_ok) { false }

        it { is_expected.not_to be_success }
      end

      context 'and bad_gem is loaded correctly' do
        let(:gem_loads_ok) { true }

        it { is_expected.to be_success }
      end
    end
  end

  describe '#detail' do
    subject(:detail) { diagnostic.detail }

    before do
      stub_gem_installed('bad_gem', gem_installed)
    end

    context 'when bad_gem is not installed' do
      let(:gem_installed) { false }

      context 'and allow_gem_not_installed is false' do
        let(:allow_gem_not_installed) { false }

        it { is_expected.to match(/bundle pristine bad_gem/) }
      end

      context 'and allow_gem_not_installed is true' do
        let(:allow_gem_not_installed) { true }

        it { is_expected.to be_nil }
      end
    end

    context 'when bad_gem is installed' do
      let(:gem_installed) { true }

      before do
        stub_gem_loads_ok('bad_gem', gem_loads_ok)
      end

      context 'and bad_gem cannot be loaded' do
        let(:gem_loads_ok) { false }

        it { is_expected.to match(/bundle pristine bad_gem/) }
      end

      context 'and bad_gem is loaded correctly' do
        let(:gem_loads_ok) { true }

        it { is_expected.to be_nil }
      end
    end
  end

  def stub_gem_installed(gem_name, success)
    stub_shellout("/home/git/gdk/support/bundle-exec gem list -i #{gem_name}", success)
  end

  def stub_gem_loads_ok(gem_name, success)
    stub_shellout("/home/git/gdk/support/bundle-exec ruby -r #{gem_name} -e 'nil'", success)
  end

  def stub_shellout(cmd, success)
    shellout_double = instance_double(Shellout, success?: success)

    allow(Shellout).to receive(:new).with(cmd, chdir: '/home/git/gdk/gitlab').and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(display_output: false, display_error: false).and_return(shellout_double)

    shellout_double
  end
end
