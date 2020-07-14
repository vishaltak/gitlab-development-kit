# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Dependencies do
  describe GDK::Dependencies::Checker do
    describe '.parse_version' do
      it 'returns the version in the string' do
        expect(described_class.parse_version('foo 1.2 bar')).to eq('1.2')
        expect(described_class.parse_version('foo 1.2.3.4.5.6 bar')).to eq('1.2.3.4.5.6')
      end

      it 'uses the given prefix' do
        expect(described_class.parse_version('1.2.3 v4.5.6', prefix: 'v')).to eq('4.5.6')
      end

      it 'ignores suffixes' do
        expect(described_class.parse_version('1.2.3-foo+foo')).to eq('1.2.3')
      end

      it 'requires at least two numeric segments' do
        expect(described_class.parse_version('1')).to be_nil
      end
    end
  end
end
