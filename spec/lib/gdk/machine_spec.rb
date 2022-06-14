# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Machine do
  subject { described_class }

  describe '.linux?' do
    before do
      allow(RbConfig::CONFIG).to receive(:[]).and_call_original
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
    end

    context 'on a macOS system' do
      let(:host_os) { 'darwin' }

      it 'returns false' do
        expect(subject.linux?).to be(false)
      end
    end

    context 'on a Linux system' do
      let(:host_os) { 'linux' }

      it 'returns true' do
        expect(subject.linux?).to be(true)
      end
    end
  end

  describe '.macos?' do
    before do
      allow(RbConfig::CONFIG).to receive(:[]).and_call_original
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
    end

    context 'on a Linux system' do
      let(:host_os) { 'linux' }

      it 'returns false' do
        expect(subject.macos?).to be(false)
      end
    end

    context 'on a macOS system' do
      let(:host_os) { 'darwin' }

      it 'returns true' do
        expect(subject.macos?).to be(true)
      end
    end
  end

  describe '.platform' do
    let(:host_os) { nil }

    before do
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
    end

    context 'when macOS' do
      let(:host_os) { 'Darwin' }

      it 'returns darwin' do
        expect(subject.platform).to eq('darwin')
      end
    end

    context 'when Linux' do
      let(:host_os) { 'Linux' }

      it 'returns linux' do
        expect(subject.platform).to eq('linux')
      end
    end

    context 'when neither macOS of Linux' do
      let(:host_os) { 'NotSure' }

      it 'returns unknown' do
        expect(subject.platform).to eq('unknown')
      end
    end
  end

  describe '.x86_64?' do
    before do
      allow(GDK::Machine).to receive(:architecture).and_return(fake_platform)
    end

    context 'when CPU is reporting an x86_64 architecture' do
      let(:fake_platform) { 'x86_64' }

      it 'returns true' do
        expect(subject.x86_64?).to be_truthy
      end
    end

    context 'when CPU is reporting an ARM based architecture' do
      let(:fake_platform) { 'arm64' }

      it 'returns false' do
        expect(subject.x86_64?).to be_falsey
      end
    end
  end

  describe '.arm64?' do
    before do
      allow(GDK::Machine).to receive(:architecture).and_return(fake_platform)
    end

    context 'when CPU is reporting arm64 architecture' do
      let(:fake_platform) { 'arm64' }

      it 'returns true' do
        expect(subject.arm64?).to be_truthy
      end
    end

    context 'when CPU is reporting aarch64 architecture' do
      let(:fake_platform) { 'aarch64' }

      it 'returns true' do
        expect(subject.arm64?).to be_truthy
      end
    end

    context 'when CPU is reporting x86_64 architecture' do
      let(:fake_platform) { 'x86_64' }

      it 'returns false' do
        expect(subject.arm64?).to be_falsey
      end
    end
  end

  describe '.architecture' do
    context 'when in a x86_64' do
      it 'returns x86_64' do
        allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('x86_64')

        expect(subject.architecture).to eq('x86_64')
      end
    end

    context 'when in an ARMv8 / Apple Silicon' do
      it 'returns arch64' do
        allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('arm64')

        expect(subject.architecture).to eq('arm64')
      end
    end
  end
end
