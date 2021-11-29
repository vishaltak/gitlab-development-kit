# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  gem 'lefthook', '~> 0.7.0', require: false
  gem 'rake', '~> 13.0.0'
  gem 'yard', '~> 0.9.0', require: false
end

group :test do
  gem 'gitlab-styles', '~> 6.5.0', require: false
  gem 'pry-byebug', '~> 3.9.0', require: false
  gem 'rspec', '~> 3.10.0', require: false
  gem 'rspec_junit_formatter', '~> 0.4.0', require: false
  gem 'simplecov-cobertura', '~> 2.0.0', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 2.5.0', require: false
end
