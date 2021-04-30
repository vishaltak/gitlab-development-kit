# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigType::Path do
  let(:value) { nil }
  let(:key) { 'test_key' }
  let(:yaml) { { key => value } }
  let(:builder) { GDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

  subject { described_class.new(parent: GDK.config, builder: builder) }

  before do
    stub_pg_bindir
    stub_gdk_yaml(yaml)
  end

  describe '#cast_value' do
    context 'when value is a String' do
      it 'returns /tmp' do
        expect(described_class.cast_value('/tmp')).to eq('/tmp')
      end
    end

    context 'when value is a Integer' do
      it 'raises an exception' do
        expect { described_class.cast_value(1) }.to raise_error(TypeError, "'1' does not appear to be a valid Path.")
      end
    end
  end

  describe '#value_valid?' do
    context 'when value is a valid String' do
      it 'returns true' do
        expect(described_class.value_valid?('/tmp')).to eq(true)
      end
    end

    context 'when value is an Invalid String' do
      it 'returns false' do
        expect(described_class.value_valid?('/nonexistent')).to eq(false)
      end
    end
  end

  describe '#parse' do
    context 'when value is initialized with a String' do
      let(:value) { '/tmp' }

      it 'returns true' do
        expect(subject.parse).to eq(true)
      end
    end

    context 'when value is initialized with an Integer' do
      let(:value) { 123 }

      it 'raises an exception' do
        expect { subject.parse }.to raise_error(TypeError, "Value '123' for #{key} is not a valid path.")
      end
    end
  end
end
