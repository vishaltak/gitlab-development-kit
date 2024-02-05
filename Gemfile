# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'lefthook', '~> 1.6.1', require: false
  gem 'rake', '~> 13.1.0'
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.6.0", require: false
  gem 'yard', '~> 0.9.34', require: false
  gem 'pry-byebug' # See doc/howto/pry.md
end

group :test do
  gem 'gitlab-styles', '~> 11.0.0', require: false
  gem 'irb', '~> 1.11.1', require: false
  gem 'rspec', '~> 3.13.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 4.6.0', require: false
  gem 'resolv', '~> 0.3.0', require: false
end

gem 'gitlab-sdk', '~> 0.3.0'
gem 'sentry-ruby', '~> 5.16', '>= 5.16.1'
