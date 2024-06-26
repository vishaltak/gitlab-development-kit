# frozen_string_literal: true

RSpec.describe GDK::Diagnostic do
  describe '.all' do
    it 'creates instances of all GDK::Diagnostic classes' do
      expect { described_class.all }.not_to raise_error
    end

    it 'contains only diagnostic classes' do
      diagnostic_classes = [
        GDK::Diagnostic::Environment,
        GDK::Diagnostic::RvmAndAsdf,
        GDK::Diagnostic::MacPorts,
        GDK::Diagnostic::Bundler,
        GDK::Diagnostic::Version,
        GDK::Diagnostic::Configuration,
        GDK::Diagnostic::Dependencies,
        GDK::Diagnostic::PendingMigrations,
        GDK::Diagnostic::PostgreSQL,
        GDK::Diagnostic::PGUser,
        GDK::Diagnostic::Geo,
        GDK::Diagnostic::Praefect,
        GDK::Diagnostic::Gitaly,
        GDK::Diagnostic::Gitlab,
        GDK::Diagnostic::Status,
        GDK::Diagnostic::Re2,
        GDK::Diagnostic::Golang,
        GDK::Diagnostic::StaleData,
        GDK::Diagnostic::StaleServices,
        GDK::Diagnostic::Chromedriver,
        GDK::Diagnostic::FileWatches,
        GDK::Diagnostic::Hostname,
        GDK::Diagnostic::Nginx
      ]

      expect(described_class.all.map(&:class)).to eq(diagnostic_classes)
    end
  end
end
