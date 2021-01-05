#!/usr/bin/env ruby

=begin
%x[gdk status].split("\n").each do |line|
  # run: ./services/gitlab-pages: (pid 71130) 4188s, normally down; run: log: (pid 56293) 6118s
  p line.match(/\A\run: .\/serviecsz/)
end
=end

Dir['services/*/supervise/pid'].each do |pid_file|
  pid = File.read(pid_file).chomp
  puts format('pid_file=[%s], pid=[%s]', pid_file, pid)
end
