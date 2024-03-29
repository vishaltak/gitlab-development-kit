# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'gitlab_development_kit'

Gem::Specification.new do |spec|
  spec.name          = 'gitlab-development-kit'
  spec.version       = GDK::GEM_VERSION
  spec.authors       = ['Jacob Vosmaer', 'GitLab']
  spec.email         = ['gitlab_rubygems@gitlab.com']

  spec.summary       = 'CLI for GitLab Development Kit'
  spec.description   = 'CLI for GitLab Development Kit.'
  spec.homepage      = 'https://gitlab.com/gitlab-org/gitlab-development-kit'
  spec.license       = 'MIT'
  spec.files         = ['lib/gitlab_development_kit.rb']
  spec.executables   = ['gdk']

  spec.required_ruby_version = '>= 3.0.5'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'gitlab-sdk', '~> 0.3.1'
  spec.add_dependency 'rake', '~> 13.1'
  spec.add_dependency 'sentry-ruby', '~> 5.17'
end
