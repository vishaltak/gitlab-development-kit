# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Start do
  let(:hooks) { %w[date] }

  before do
    allow_any_instance_of(GDK::Config).to receive_message_chain('gdk.start_hooks').and_return(hooks)
  end

  context 'with no extra arguments' do
    it 'executes hooks and starts all enabled services' do
      expect(GDK::Hooks).to receive(:with_hooks).with(hooks, 'gdk start').and_yield
      expect_runit_to_execute(command: 'start', args: [])

      expect { subject.run }.to output(/GitLab will be available at/).to_stdout
    end
  end

  context 'with extra arguments' do
    it 'executes hooks and starts specified services' do
      services = %w[rails-web]

      expect(GDK::Hooks).to receive(:with_hooks).with(hooks, 'gdk start').and_yield
      expect_runit_to_execute(command: 'start', args: services)

      subject.run(services)
    end
  end

  def expect_runit_to_execute(command:, args: [])
    expect(Runit).to receive(:sv).with(command, args).and_return(true)
  end
end
