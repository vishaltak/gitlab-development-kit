# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic::RubyGems do
  before do
    stub_const('GDK::Diagnostic::RubyGems::GEMS_TO_CHECK', %w[bad_gem])
  end

  describe '#diagnose' do
    xit 'is a no-op' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'when bad_gem can not be loaded' do
      xit 'returns false' do
        allow_any_instance_of(described_class).to receive(:require).with('bad_gem').and_raise(LoadError, 'failed to load')

        expect(subject).not_to be_success
      end
    end

    context 'when bad_gem is loaded correctly' do
      xit 'returns true' do
        allow_any_instance_of(described_class).to receive(:require).with('bad_gem').and_return(true)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when bad_gem cannot be loaded' do
      xit 'returns a message' do
        allow_any_instance_of(described_class).to receive(:require).with('bad_gem').and_raise(LoadError, 'failed to load')

        expect(subject.detail).to match(/gem pristine bad_gem/)
      end
    end

    context 'when bad_gem is loaded correctly' do
      xit 'returns no message' do
        allow_any_instance_of(described_class).to receive(:require).with('bad_gem').and_return(true)

        expect(subject.detail).to be_nil
      end
    end
  end
end
