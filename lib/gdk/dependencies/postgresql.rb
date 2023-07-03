# frozen_string_literal: true

module GDK
  module Dependencies
    # PostgreSQL installation dependency
    #
    # In a GDK environment you may have multiple PostgreSQL versions installed and
    # available in your system, which may be required for doing upgrades from an
    # old version to a new one
    #
    # This contains the required code to handle the binaries in multiple versions
    # with the supported dependencies providers
    module PostgreSQL
      autoload :Binaries, 'gdk/dependencies/postgresql/binaries'
    end
  end
end
