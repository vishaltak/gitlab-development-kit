# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Postgresql do
  let(:config) { GDK::Config.new(yaml: yaml) }

  before do
    allow(GDK).to receive(:config) { config }
  end

  describe '#use_tcp?' do
    context 'with host defined to a path' do
      let(:yaml) do
        {
          postgresql: {
            host: '/home/git/gdk/postgresql'
          }
        }
      end

      it 'returns false' do
        expect(subject).not_to be_use_tcp
      end
    end

    context 'with host defined to a hostname' do
      let(:yaml) do
        {
          postgresql: {
            host: 'localhost'
          }
        }
      end

      it 'returns true' do
        expect(subject).to be_use_tcp
      end
    end
  end
end
