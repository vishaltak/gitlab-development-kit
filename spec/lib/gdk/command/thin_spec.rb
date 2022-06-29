# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Thin do
  let(:args) { [] }

  it 'displays deprecation warning and returns false' do
    stub_const('MSG', "gdk thin is deprecated. Use 'gdk rails s -e GITLAB_RAILS_RACK_TIMEOUT_ENABLE=false' instead.")

    expect(GDK::Output).to receive(:puts).with(MSG)
    expect(subject.run(args)).to be(false)
  end
end
