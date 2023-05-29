# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'lefthook', '~> 1.4.1', require: false
  gem 'rake', '~> 13.0.6'
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.6.0", require: false
  gem 'yard', '~> 0.9.34', require: false
end

group :test do
  gem 'gitlab-styles', '~> 10.0.0', require: false
  gem 'irb', '~> 1.6.4', require: false
  gem 'rspec', '~> 3.12.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 3.10.0', require: false
  gem 'resolv', '~> 0.2.2', require: false
end
