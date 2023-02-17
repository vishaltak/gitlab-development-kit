# frozen_string_literal: true

filename = './update.txt'
content  = File.read(filename)
dashes   = '-' * 80

lines_with_dashes = content.scan(/^#{dashes}\n(.*?)\n#{dashes}$/m).map(&:first)
duplicates = lines_with_dashes.select { |line| lines_with_dashes.count(line) > 1 }.uniq

if duplicates.empty?
  puts 'No duplicated lines found.'
else
  puts 'Duplicated lines found:'
  puts ''
  puts duplicates
end
