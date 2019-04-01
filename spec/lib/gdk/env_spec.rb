# frozen_string_literal: true

require 'spec_helper'
require 'gdk/env'

describe GDK::Env do
  describe 'env vars' do
    subject { described_class.set_env_vars }

    shared_context 'file does not exist' do |filename|
      before do
        allow(File).to receive(:exist?).and_call_original
        expect(File).to receive(:exist?).with(filename).and_return(false)
      end
    end

    shared_context 'file exists' do |filename|
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:read).and_call_original

        expect(File).to receive(:exist?).with(filename).and_return(true)
        expect(File).to receive(:read).with(filename).and_return('file-value')
      end
    end

    before do
      @original_env = ENV.to_hash
    end

    after do
      ENV.replace(@original_env)
    end

    describe 'host' do
      context 'file does not exist' do
        include_context 'file does not exist', 'host'

        it 'defaults to localhost' do
          subject

          expect(ENV['host']).to eq('localhost')
        end
      end

      context 'file exists' do
        include_context 'file exists', 'host'

        it 'uses the value of the file' do
          subject

          expect(ENV['host']).to eq('file-value')
        end
      end
    end

    describe 'port' do
      context 'file does not exist' do
        include_context 'file does not exist', 'port'

        it 'defaults to 3000' do
          subject

          expect(ENV['port']).to eq('3000')
        end
      end

      context 'file exists' do
        include_context 'file exists', 'port'

        it 'uses the value of the file' do
          subject

          expect(ENV['port']).to eq('file-value')
        end
      end
    end

    describe 'relative_url_root' do
      context 'file does not exist' do
        include_context 'file does not exist', 'relative_url_root'

        it 'defaults to /' do
          subject

          expect(ENV['relative_url_root']).to eq('/')
        end
      end

      context 'file exists' do
        include_context 'file exists', 'relative_url_root'

        it 'uses the value of the file' do
          subject

          expect(ENV['relative_url_root']).to eq('file-value')
        end
      end
    end
  end
end
