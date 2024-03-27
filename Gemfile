# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: 'gem/'

group :development do
  gem 'lefthook', '~> 1.6.7', require: false
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.6.0", require: false
  gem 'yard', '~> 0.9.36', require: false
  gem 'pry-byebug' # See doc/howto/pry.md
end

group :test do
  gem 'gitlab-styles', '~> 11.0.0', require: false
  gem 'irb', '~> 1.12.0', require: false
  gem 'rspec', '~> 3.13.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 4.7.0', require: false
  gem 'resolv', '~> 0.4.0', require: false
end
