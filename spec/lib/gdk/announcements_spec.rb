# frozen_string_literal: true

RSpec.describe GDK::Announcements, :gdk_root do
  let(:header) { 'the header' }
  let(:body) { 'the body' }
  let(:first_announcement) { instance_double(GDK::Announcement, render?: true) }
  let(:first_announcement_file) { 'announcement.yml' }

  describe '#render_all' do
    before do
      allow(Dir).to receive(:glob).and_return([first_announcement_file])
      stub_announcement(first_announcement_file, first_announcement)
    end

    it 'renders an announcement to the terminal' do
      expect(GDK::Output).to receive(:puts).once
      expect(first_announcement).to receive(:render).once.and_return(true)

      subject.render_all
    end

    context 'with multiple announcements' do
      let(:second_announcement) { instance_double(GDK::Announcement, render?: true) }
      let(:second_announcement_file) { 'announcement2.yml' }
      let(:second_announcement_file_path) { Pathname.new(second_announcement_file) }

      before do
        allow(Dir).to receive(:glob).and_return([first_announcement_file, second_announcement_file])
        stub_announcement(second_announcement_file, second_announcement)
      end

      it 'renders all announcements to the terminal' do
        expect(GDK::Output).to receive(:puts).twice
        expect(first_announcement).to receive(:render).and_return(true)
        expect(second_announcement).to receive(:render).and_return(true)

        subject.render_all
      end
    end
  end

  private

  def stub_announcement(announcement_file, announcement)
    announcement_file_path = Pathname.new(announcement_file)
    allow(GDK::Announcement).to receive(:from_file).with(announcement_file_path).and_return(announcement)
  end
end
