# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::TestURL do
  let(:default_url) { 'http://127.0.0.1:3000/users/sign_in' }

  before do
    stub_const('GDK::TestURL::MAX_ATTEMPTS', 2)
  end

  subject { described_class.new }

  describe 'initialize' do
    it 'raises UrlAppearsInvalid exception if URL invalid' do
      expect { described_class.new('invalid-url') }.to raise_error(GDK::TestURL::UrlAppearsInvalid)
    end

    it "doesn't raise UrlAppearsInvalid exception when URL is valid" do
      expect(described_class.new).to be_instance_of(described_class)
    end
  end

  describe '#wait' do
    shared_examples "a URL that's down" do
      it 'checks if the URL is up but returns false' do
        allow(subject).to receive(:check_url).and_return(false)

        freeze_time do
          result = nil

          expected_message = Regexp.escape("#{default_url} does not appear to be up. Waited 0.0 second(s).")
          expect { result = subject.wait }.to output(/#{expected_message}/).to_stdout
          expect(result).to be(false)
        end
      end
    end

    shared_examples "a URL that's up" do
      it 'checks if the URL is up but returns true' do
        allow(subject).to receive(:check_url).and_return(true)

        freeze_time do
          result = nil

          expected_message = Regexp.escape("#{default_url} is up (#{last_response_reason}). Took 0.0 second(s).")
          expect { result = subject.wait }.to output(/#{expected_message}/).to_stdout
          expect(result).to be(true)
        end
      end
    end

    context 'when URL is down' do
      it_behaves_like "a URL that's down"
    end

    context 'when URL is up' do
      it_behaves_like "a URL that's up" do
        let(:last_response_reason) { '200 OK' }
        let!(:http_helper_double) { stub_test_url_http_helper(last_response_reason) }
      end
    end
  end

  describe '#check_url' do
    let(:expect_second_attempt) { nil }

    shared_examples "a URL that's down" do
      it 'checks if the URL is up but returns false' do
        expected_message = []

        allow(http_helper_double).to receive(:head_up?).and_return(false)
        expect(subject).to receive(:sleep).with(3).twice

        if verbose
          expected_message << "\n> Testing attempt #1.."
          expected_message << last_response_reason

          if expect_second_attempt
            expected_message << "\n> Testing attempt #2.."
            expected_message << last_response_reason
          end

          expected_message << ''
        else
          expected_message << '..'
        end

        freeze_time do
          result = nil
          expect { result = subject.check_url(verbose: verbose) }.to output(expected_message.join("\n")).to_stdout
          expect(result).to be(false)
        end
      end
    end

    shared_examples "a URL that's up" do
      it 'checks if the URL is up but returns true' do
        expected_message = []

        allow(http_helper_double).to receive(:head_up?).and_return(true)

        if verbose
          expected_message << "\n> Testing attempt #1.."
          expected_message << last_response_reason
        end

        expected_message << "\n"

        result = nil
        expect { result = subject.check_url(verbose: verbose) }.to output(expected_message.join("\n")).to_stdout
        expect(result).to be(true)
      end
    end

    context 'verbose is enabled' do
      let(:verbose) { true }

      context 'when URL is down' do
        it_behaves_like "a URL that's down" do
          let(:expect_second_attempt) { true }
          let(:last_response_reason) { '502 Bad Gateway' }
          let(:http_helper_double) { stub_test_url_http_helper(last_response_reason) }
        end
      end

      context 'when URL is up' do
        it_behaves_like "a URL that's up" do
          let(:last_response_reason) { '200 OK' }
          let(:http_helper_double) { stub_test_url_http_helper(last_response_reason) }
        end
      end
    end

    context 'verbose is disabled' do
      let(:verbose) { false }

      context 'when URL is down' do
        it_behaves_like "a URL that's down" do
          let(:expect_second_attempt) { true }
          let(:last_response_reason) { '502 Bad Gateway' }
          let(:http_helper_double) { stub_test_url_http_helper }
        end
      end

      context 'when URL is up' do
        it_behaves_like "a URL that's up" do
          let(:expect_second_attempt) { false }
          let(:last_response_reason) { '302 OK' }
          let(:http_helper_double) { stub_test_url_http_helper(last_response_reason) }
        end
      end
    end
  end

  describe '#check_url_oneshot' do
    it 'calls #check_url, overriding max_attempts, verbose and silent' do
      expect(subject).to receive(:check_url).with(override_max_attempts: 1, verbose: false, silent: true)

      subject.check_url_oneshot
    end
  end

  def stub_test_url_http_helper(last_response_reason = '')
    uri = URI.parse(default_url)
    http_helper_double = instance_double(GDK::HTTPHelper, last_response_reason: last_response_reason)
    allow(GDK::HTTPHelper).to receive(:new).with(uri, read_timeout: 60, open_timeout: 60, cache_response: false).and_return(http_helper_double)

    http_helper_double
  end
end
