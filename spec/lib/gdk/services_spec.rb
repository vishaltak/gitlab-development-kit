# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services do
  describe 'ALL' do
    it 'contains Service classes' do
      service_classes = %i[
        Redis
      ]

      expect(described_class::ALL).to eq(service_classes)
    end
  end

  describe '.enabled' do
    it 'contains enabled Service classes' do
      service_classes = [
        GDK::Services::Redis
      ]

      expect(described_class.enabled.map(&:class)).to eq(service_classes)
    end
  end
end
