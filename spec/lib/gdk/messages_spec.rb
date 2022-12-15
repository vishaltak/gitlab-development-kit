# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Messages, :gdk_root do
  let(:header) { 'the header' }
  let(:body) { 'the body' }

  describe '#render_all' do
    it 'renders a message to the terminal' do
      message_double = instance_double(GDK::Message, render?: true)

      allow(GDK::Message).to receive(:new).and_return(message_double)

      expect(message_double).to receive(:render).and_return(true)

      subject.render_all
    end
  end
end
