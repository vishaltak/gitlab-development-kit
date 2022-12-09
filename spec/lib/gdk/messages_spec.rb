# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Messages do
  let(:header) { 'the header' }
  let(:body) { 'the body' }

  describe '#render_all' do
    it 'renders a message to the terminal' do
      message_double = instance_double(GDK::Message, render?: true)

      allow(GDK::Message).to receive(:new).and_return(message_double)

      subject.add_message(header, body)

      expect(message_double).to receive(:render).and_return(true)

      subject.render_all
    end
  end

  describe '#add_message' do
    it 'adds a message to the end of the messages array' do
      subject.add_message(header, body)

      last_message = subject.messages.last

      expect(last_message).to be_instance_of(GDK::Message)
      expect(last_message.header).to eq(header)
      expect(last_message.body).to eq(body)
    end
  end
end
