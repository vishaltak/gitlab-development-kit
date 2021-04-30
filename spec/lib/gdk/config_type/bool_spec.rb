# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::ConfigType::Bool do
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
    context 'when value is a Boolean' do
      it 'returns true' do
        expect(described_class.cast_value(true)).to eq(true)
      end
    end

    context 'when value is a String' do
      it 'raises an exception' do
        expect { described_class.cast_value('test') }.to raise_error(TypeError, "'test' does not appear to be a valid Boolean.")
      end
    end
  end

  describe '#parse' do
    context 'when value is initialized with a Boolean' do
      let(:value) { true }

      it 'returns true' do
        expect(subject.parse).to eq(true)
      end
    end

    context 'when value is initialized with a String' do
      let(:value) { 'test' }

      it 'raises an exception' do
        expect { subject.parse }.to raise_error(TypeError, "Value 'test' for #{key} is not a valid bool.")
      end
    end
  end
end
