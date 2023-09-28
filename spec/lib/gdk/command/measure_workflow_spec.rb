# frozen_string_literal: true

require 'spec_helper'
require 'helpers/measure_helper'

RSpec.describe GDK::Command::MeasureWorkflow do
  include MeasureHelper

  let(:docker_running) { nil }

  before do
    stub_tty(false)
  end

  describe '#run' do
    before do
      stub_docker_check(is_running: docker_running)
    end

    context 'when an empty workflow array is provided' do
      it 'aborts' do
        expected_error = 'ERROR: Please add a valid workflow(s) as an argument (e.g. repo_browser)'
        workflows = []

        expect { subject.run(workflows) }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    include_examples 'it checks if Docker and GDK are running', %w[repo_browser]

    context 'when Docker and GDK are running' do
      include_context 'Docker and GDK are running'

      context 'with a single workflow' do
        include_examples 'runs sitespeed via Docker', 'linux', 'workflows', %w[repo_browser]
        include_examples 'runs sitespeed via Docker', 'macOS', 'workflows', %w[repo_browser]
      end
    end
  end
end
