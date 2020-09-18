# frozen_string_literal: true

require 'spec_helper'
require 'gdk/line_in_file'
require 'tempfile'

RSpec.describe GDK::LineInFile do
  let(:content) { "first\nsecond\nthird\nfourth\n" }
  let(:tmp_file) do
    Tempfile.open('gdk_file_in_file_spec') do |f|
      f.write(content) if content
      f
    end
  end

  subject(:line_in_file) { described_class.new(tmp_file.path) }

  after do
    tmp_file.unlink
  end

  describe '#append' do
    it 'appends line to end if not found' do
      line_in_file.append(line: 'fifth')

      expect(read_tmp_file).to eq("first\nsecond\nthird\nfourth\nfifth")
    end

    it 'does nothing if line exists' do
      line_in_file.append(line: 'third')

      expect(read_tmp_file).to eq(content)
    end

    it 'does nothing if line regexp matches' do
      line_in_file.append(line: 'third', regexp: /th/)

      expect(read_tmp_file).to eq(content)
    end
  end

  describe '#remove' do
    it 'removes all lines matching regexp' do
      line_in_file.remove(regexp: /th/)

      expect(read_tmp_file).to eq("first\nsecond\n")
    end
  end

  def read_tmp_file
    File.read(tmp_file)
  end
end
