# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Dependencies do
  let(:tmp_path) { Dir.mktmpdir('gdk-path') }

  before do
    stub_env('PATH', tmp_path)
  end

  describe '.homebrew_available?' do
    it 'returns true when Homebrew is available in PATH' do
      create_dummy_executable('brew')

      expect(described_class.homebrew_available?).to be_truthy
    end

    it 'returns false when Homebrew is not available in PATH' do
      expect(described_class.homebrew_available?).to be_falsey
    end
  end

  describe '.macports_available?' do
    it 'returns true when Macports is available in PATH' do
      create_dummy_executable('port')

      expect(described_class.macports_available?).to be_truthy
    end

    it 'returns false when Macports is not available in PATH' do
      expect(described_class.macports_available?).to be_falsey
    end
  end

  describe '.linux_apt_available?' do
    it 'returns true when APT is available in PATH' do
      create_dummy_executable('apt')

      expect(described_class.linux_apt_available?).to be_truthy
    end

    it 'returns false when APT is not available in PATH' do
      expect(described_class.linux_apt_available?).to be_falsey
    end
  end

  describe '.find_executable' do
    it 'returns the full path of the executable' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable('dummy')).to eq(executable)
    end

    it 'returns nil when executable cant be found' do
      expect(described_class.find_executable('non-existent')).to eq(nil)
    end
  end

  describe '.executable_exist?' do
    it 'returns true if an executable exists in the PATH' do
      create_dummy_executable('dummy')

      expect(described_class.executable_exist?('dummy')).to be_truthy
    end

    it 'returns false when no exectuable can be found' do
      expect(described_class.executable_exist?('non-existent')).to be_falsey
    end
  end

  def create_dummy_executable(name)
    path = File.join(tmp_path, name)
    FileUtils.touch(path)
    File.chmod(0o755, path)

    path
  end
end
