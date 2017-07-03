require 'tty'
require 'socket'
require 'yaml'

puts "set_ip configuration: start"

# Search ip on this machine
addr_infos = Socket.ip_address_list
ipv4 = []
addr_infos.each do |addr_info|
  ip = addr_info.ip_address
  # puts "ip: #{ip}"
  if /\A[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\z/ =~ ip
    ipv4 << ip
  end
end
ipv4.uniq

# Ask which ip is the best
prompt = TTY::Prompt.new
ip = prompt.select("Choose ip", ipv4)

# Overwrite files

# host
File.open("#{$gdk_root}/host", 'w') { |file| file.write(ip) }

# gitlab/config/gitlab.yml
File.read("#{$gdk_root}/gitlab/config/gitlab.yml").tap do |content|
  new_content = content.gsub(/(^production:.*?gitlab:.*?host:)\s*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|localhost)/m, '\1 '+ip)
  File.open("#{$gdk_root}/gitlab/config/gitlab.yml", 'w') { |file| file.write(new_content) }
end

# ~/.gitlab-runner/config.toml
runner_file = prompt.ask('Tell me your runner configuration file', default: ENV['HOME']+'/.gitlab-runner/config.toml')
# puts "runner_file: #{runner_file}"
File.read(runner_file).tap do |content|
  new_content = content.gsub(/(url = "http:\/\/)([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|localhost)(::\d+\/(ci|)")/, '\1'+ip+'\3')
  File.open(runner_file, 'w') { |file| file.write(new_content) }
end

puts "set_ip configuration: done"
