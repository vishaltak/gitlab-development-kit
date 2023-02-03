# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::RubyGems do
  before do
    stub_const('GDK::Diagnostic::RubyGems::GITLAB_GEMS_TO_CHECK', %w[bad_gem])
  end

  describe '#success?' do
    context 'when bad_gem can not be loaded' do
      it 'returns false' do
        stub_gem_list('bad_gem', false)

        expect(subject).not_to be_success
      end
    end

    context 'when bad_gem is loaded correctly' do
      it 'returns true' do
        stub_gem_list('bad_gem', true)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when bad_gem cannot be loaded' do
      it 'returns a message' do
        stub_gem_list('bad_gem', false)

        expect(subject.detail).to match(/gem pristine bad_gem/)
      end
    end

    context 'when bad_gem is loaded correctly' do
      it 'returns no message' do
        stub_gem_list('bad_gem', true)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_gem_list(gem_name, success)
    shellout_double = instance_double(Shellout, success?: success, try_run: success)
    cmd = "/home/git/gdk/support/bundle-exec gem list -i #{gem_name}"

    allow(Shellout).to receive(:new).with(cmd, chdir: '/home/git/gdk/gitlab').and_return(shellout_double)

    shellout_double
  end
end
