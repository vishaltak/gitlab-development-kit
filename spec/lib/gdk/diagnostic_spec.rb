# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Diagnostic do
  describe '.all' do
    it 'creates instances of all GDK::Diagnostic classes' do
      expect { described_class.all }.not_to raise_error
    end

    it 'contains our diagnostic classes' do
      serial_classes = [
        GDK::Diagnostic::Configuration,
      ]
      parallel_classes = [
        GDK::Diagnostic::RubyGems,
        GDK::Diagnostic::Version,
        GDK::Diagnostic::Git,
        GDK::Diagnostic::Dependencies,
        GDK::Diagnostic::PendingMigrations,
        GDK::Diagnostic::PostgreSQL,
        GDK::Diagnostic::Geo,
        GDK::Diagnostic::Status,
        GDK::Diagnostic::Re2,
        GDK::Diagnostic::Golang,
        GDK::Diagnostic::StaleServices
      ]

      expect(described_class.serial_classes.map(&:class)).to eq(serial_classes)
      expect(described_class.parallel_classes.map(&:class)).to eq(parallel_classes)
      expect(described_class.all.map(&:class)).to eq(serial_classes + parallel_classes)
    end
  end
end
