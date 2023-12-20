# frozen_string_literal: true

module GDK
  # Execute contains all adapters to execute external code
  #
  # Instead of relying on Shellout directly, we wrap those dependencies
  # into a more reusable API
  module Execute
    autoload :Rake, 'gdk/execute/rake'
  end
end
