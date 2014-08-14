require 'timeout'

module PuppetX
  module ConnectionValidator

    # This module provides the base logic for the various provider implementations
    # for the `connection_validator` type.
    #
    # It is used as a mix-in (mostly because the type/provider model abstracts
    # away the ability to use regular inheritance, as far as I can tell), and it
    # assumes that all of the providers that include it will define the following
    # methods:
    #
    # `#validate()`: should validate the properties and parameters assigned to
    #      the resource and raise an error if they are invalid
    # `#attempt_connection()`: should attempt to make a connection to the appropriate
    #      destination, and return `true` or `false` to indicate whether or not
    #      the connection was successful.
    # `#connection_description()`: a string that can be logged or used in an
    #      error message to convey to the user what the target destination that
    #      we are trying to connect to is.  e.g., for an HTTP connection, the
    #      most meaningful value would be the URL.
    # `#connection_type()`: a string that can be logged or used in an error message
    #     that describes the type of connection.  This will probably be the same
    #     or similar to the name of the provider, e.g. "HTTP", "TCP", etc.

    def exists?
      # this is horrible--Puppet ought to be calling into the provider
      # for validation as a normal part of the type/provider life cycle,
      # but I couldn't find a place where that happens so I'm calling my own
      # validation hook here.
      validate
      timeout = Float(resource[:timeout] || 0)
      if timeout > 0
        attempt_connection_with_timeout(timeout)
      else
        attempt_connection_without_timeout
      end
    end

    def create
      # If `#create` is called, that means that `#exists?` returned false, which
      # means that the connection could not be established... so we need to
      # cause a failure here.
      raise Puppet::Error, "Unable to establish #{connection_type} conn to server! (#{connection_description})"
    end

    private

    def attempt_connection_with_timeout(timeout)
      Timeout.timeout(timeout) do
        retry_interval = Float(resource[:retry_interval] || 2)
        until attempt_connection
          Puppet.notice("Failed to connect to '#{connection_description}'; sleeping #{retry_interval} seconds before retry")
          sleep retry_interval
        end
        true
      end
    rescue Timeout::Error
      Puppet.notice("Failed to connect to '#{connection_description}' within timeout window of #{timeout} seconds; giving up.")
      false
    end

    def attempt_connection_without_timeout
      if attempt_connection
        true
      else
        Puppet.notice("Failed to connect to '#{connection_description}'")
        false
      end
    end

  end
end
