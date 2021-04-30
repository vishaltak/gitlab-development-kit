# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigType::Hash do
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
    context 'when value is a Hash' do
      it 'returns {}' do
        expect(described_class.cast_value({})).to eq({})
      end
    end

    context 'when value is a Integer' do
      it 'raises an exception' do
        expect { described_class.cast_value(1) }.to raise_error(TypeError, "'1' does not appear to be a valid Hash.")
      end
    end
  end

  describe '#parse' do
    context 'when value is initialized with a Hash' do
      let(:value) { {} }

      it 'returns true' do
        expect(subject.parse).to eq(true)
      end
    end

    context 'when value is initialized with an Integer' do
      let(:value) { 123 }

      it 'raises an exception' do
        expect { subject.parse }.to raise_error(TypeError, "Value '123' for #{key} is not a valid hash.")
      end
    end
  end
end
