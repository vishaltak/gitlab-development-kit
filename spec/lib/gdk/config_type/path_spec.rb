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

  describe '#parse' do
    context 'when value is initialized with a string' do
      let(:value) { '/tmp' }

      it 'returns true' do
        expect(subject.parse).to be(true)
      end
    end
  end
end
