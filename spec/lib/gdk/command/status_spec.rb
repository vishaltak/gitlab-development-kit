# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Status do
  context 'with no extra arguments' do
    it 'queries runit for status to all enabled services' do
      expect_runit_to_execute(command: 'status')

      expect { subject.run }.to output(/GitLab available at/).to_stdout
    end
  end

  context 'with extra arguments' do
    it 'queries runit for status to specific services only' do
      expect_runit_to_execute(command: 'status', args: ['rails-web'])

      expect { subject.run(%w[rails-web]) }.not_to output(/GitLab available at/).to_stdout
    end
  end

  def expect_runit_to_execute(command:, args: [])
    expect(Runit).to receive(:sv).with(command, args).and_return(true)
  end
end
