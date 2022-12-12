# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |gitlab_dangerfiles|
  gitlab_dangerfiles.config.files_to_category = {
    %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
    %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,
    %r{.*} => [nil]
  }.freeze

  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.import_dangerfiles(except: %w[changelog])
end
