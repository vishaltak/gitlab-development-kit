# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Thin do
  let(:args) { [] }

  it 'displays deprecation warning and returns false' do
    msg = 'This command is deprecated. Use the following command instead:'

    allow(GDK::Output).to receive(:puts)
    expect(GDK::Output).to receive(:puts).with(msg)
    expect(subject.run(args)).to be(false)
  end
end
