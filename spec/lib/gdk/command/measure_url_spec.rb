# frozen_string_literal: true

require 'spec_helper'
require 'helpers/measure_helper'

RSpec.describe GDK::Command::MeasureUrl do
  include MeasureHelper

  let(:urls) { %w[/explore] }
  let(:docker_running) { nil }

  before do
    stub_tty(false)
  end

  describe '#run' do
    before do
      stub_docker_check(is_running: docker_running)
    end

    context 'when an empty URL array is provided' do
      it 'aborts' do
        expected_error = 'ERROR: Please add URL(s) as an argument (e.g. http://localhost:3000/explore, /explore or https://gitlab.com/explore)'
        urls = []

        expect { subject.run(urls) }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    include_examples 'it checks if Docker and GDK are running', %w[/explore]

    context 'when Docker and GDK are running' do
      include_context 'Docker and GDK are running'

      context 'with a single url' do
        include_examples 'runs sitespeed via Docker', 'linux', 'urls', %w[/explore]
        include_examples 'runs sitespeed via Docker', 'macOS', 'urls', %w[/explore]
      end
    end
  end
end
