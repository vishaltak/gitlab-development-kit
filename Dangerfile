# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |gitlab_dangerfiles|
  gitlab_dangerfiles.config.files_to_category = {
    %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
    %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,
    %r{.*} => [nil]
  }.freeze

  gitlab_dangerfiles.import_plugins
  gitlab_dangerfiles.import_dangerfiles
end

anything_to_post = status_report.values.any?(&:any?)

if helper.ci? && anything_to_post
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
