# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Required do
  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end
end
