# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rake', '~> 13.0.0'

group :development do
  gem 'lefthook', '~> 0.7.0', require: false
  gem 'yard', '~> 0.9.0', require: false
end

group :test do
  gem 'gitlab-styles', '~> 6.2.0', require: false
  gem 'pry-byebug', '~> 3.9.0', require: false
  gem 'rspec', '~> 3.10.0', require: false
  gem 'rspec_junit_formatter', '~> 0.4.0', require: false
  gem 'simplecov-cobertura', '~> 1.4.0', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 2.3.0', require: false
end
