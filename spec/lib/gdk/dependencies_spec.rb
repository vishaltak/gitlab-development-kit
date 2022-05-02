# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Dependencies do
  let(:tmp_path) { Dir.mktmpdir('gdk-path') }

  describe '.homebrew_available?' do
    before do
      stub_env('PATH', tmp_path)
    end

    it 'returns true when Homebrew is available in PATH' do
      create_dummy_executable('brew')

      expect(described_class.homebrew_available?).to be_truthy
    end

    it 'returns false when Homebrew is not available in PATH' do
      expect(described_class.homebrew_available?).to be_falsey
    end
  end

  describe '.macports_available?' do
    before do
      stub_env('PATH', tmp_path)
    end

    it 'returns true when Macports is available in PATH' do
      create_dummy_executable('port')

      expect(described_class.macports_available?).to be_truthy
    end

    it 'returns false when Macports is not available in PATH' do
      expect(described_class.macports_available?).to be_falsey
    end
  end

  describe '.linux_apt_available?' do
    before do
      stub_env('PATH', tmp_path)
    end

    it 'returns true when APT is available in PATH' do
      create_dummy_executable('apt')

      expect(described_class.linux_apt_available?).to be_truthy
    end

    it 'returns false when APT is not available in PATH' do
      expect(described_class.linux_apt_available?).to be_falsey
    end
  end

  def create_dummy_executable(name)
    path = File.join(tmp_path, name)
    FileUtils.touch(path)
    File.chmod(0o755, path)
  end
end
