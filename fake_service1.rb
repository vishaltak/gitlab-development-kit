# frozen_string_literal: true

def shut_down
  warn "\nShutting down gracefully..."
  $stderr.flush
  exit
end

puts "I have PID #{Process.pid}"

# Trap ^C
Signal.trap('INT') do
  # shut_down
  warn 'Ignorning INT..'
  $stderr.flush
end

# Trap `Kill `
Signal.trap('TERM') do
  # shut_down
  warn 'Ignorning TERM..'
  $stderr.flush
end

loop do
  warn Time.now
  $stderr.flush
  # sleep 1
end
