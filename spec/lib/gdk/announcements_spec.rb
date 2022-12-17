# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Announcements, :gdk_root do
  let(:header) { 'the header' }
  let(:body) { 'the body' }

  describe '#render_all' do
    it 'renders an announcement_double to the terminal' do
      announcement_double = instance_double(GDK::Announcement, render?: true)

      allow(GDK::Announcement).to receive(:new).and_return(announcement_double)

      expect(GDK::Output).to receive(:puts)
      expect(announcement_double).to receive(:render).and_return(true)

      subject.render_all
    end
  end
end
