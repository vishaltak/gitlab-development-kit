# frozen_string_literal: true

require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.for_project(self) do |dangerfiles|
  dangerfiles.import_plugins
  dangerfiles.import_dangerfiles(rules: [:changes_size, :commit_messages])
end

danger.import_plugin('danger/plugins/*.rb')

project_helper.rule_names.each do |rule|
  danger.import_dangerfile(path: File.join('danger', rule))
end

anything_to_post = status_report.values.any?(&:any?)

if helper.ci? && anything_to_post
  markdown("**If needed, you can retry the [`danger-review` job](#{ENV['CI_JOB_URL']}) that generated this comment.**")
end
