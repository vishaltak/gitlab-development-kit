# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::Re2 do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'when re2 is not installed or bad' do
      it 'returns false' do
        stub_shellout(false)

        expect(subject.success?).to be(false)
      end
    end

    context 'when re2 is OK' do
      it 'returns true' do
        stub_shellout(true)

        expect(subject.success?).to be(true)
      end
    end
  end

  describe '#detail' do
    context 'when re2 is not installed or bad' do
      it 'returns false' do
        stub_shellout(false)

        expect(subject.detail).to eq("It looks like your system re2 library may have been upgraded, and\nthe re2 gem needs to be rebuilt as a result.\n\nPlease run `cd /home/git/gdk/gitlab && gem pristine re2`.\n")
      end
    end

    context 'when re2 is OK' do
      it 'returns nil' do
        stub_shellout(true)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_shellout(success)
    shellout = instance_double('Shellout', success?: success, try_run: nil)

    cmd = ["/home/git/gdk/support/bundle-exec", "ruby", "-e", "\"require 're2'; regexp = RE2::Regexp.new('{', log_errors: false); regexp.error unless regexp.ok?\""]
    allow(Shellout).to receive(:new).with(cmd, chdir: GDK.config.gitlab.dir.to_s).and_return(shellout)

    shellout
  end
end
