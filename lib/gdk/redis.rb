# frozen_string_literal: true

module GDK
  class Redis
    def self.target_version
      Gem::Version.new(Asdf::ToolVersions.new.default_version_for('redis'))
    end
  end
end
