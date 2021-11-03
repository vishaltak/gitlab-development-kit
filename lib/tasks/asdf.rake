# frozen_string_literal: true

namespace :asdf do
  desc 'asdf: Uninstall unnecessary software'
  task :uninstall_unnecessary_software do
    Asdf::ToolVersions.new.uninstall_unnecessary_software!
  end
end
