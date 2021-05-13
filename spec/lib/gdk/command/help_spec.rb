# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Help do
  let(:gdk_root_dir) { '/home/git/gdk' }
  let(:gdk_root) { Pathname.new(gdk_root_dir) }
  let(:args) { [] }

  before do
    allow(GDK).to receive(:root).and_return(gdk_root)
  end

  it 'displays help and returns true' do
    result = nil
    help_file_contents = stub_help_file

    expect { result = subject.run(args) }.to output("#{help_file_contents}\n").to_stdout
    expect(result).to be(true)
  end

  def stub_help_file
    help_file = gdk_root.join('HELP')
    help_file_contents = 'help contents'

    allow(GDK::Logo).to receive(:print)
    allow(File).to receive(:read).with(help_file).and_return(help_file_contents)

    help_file_contents
  end
end
