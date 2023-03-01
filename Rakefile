# frozen_string_literal: true

$LOAD_PATH.unshift('./lib')

require 'fileutils'
require 'rake/clean'
require 'gdk'
require 'git/configure'
require 'gitlab-dangerfiles'

Gitlab::Dangerfiles.load_tasks

Rake.add_rakelib 'lib/tasks'
