require 'puppet_x/connection_validator'
require 'socket'

Puppet::Type.type(:connection_validator).provide(:tcp) do
  include PuppetX::ConnectionValidator

  # If there were a way to specify a docstring for a provider, I'd
  # do it here.
  #-----------------------------------------------------------------------------
  # TCP provider for connection_validator type
  #
  # This provider validates that a successful TCP connection can be established to
  # a specified host and port.  To use this provider, you must provide the
  # 'host' and 'port' parameters.
  #-----------------------------------------------------------------------------

  private

  def validate
    [:url, :scheme, :path].each do |param|
      if resource[param]
        raise Puppet::Error, "This provider does not support the parameter '#{param}'"
      end
    end

    unless resource[:host]
      resource[:host] = "localhost"
    end

    [:host, :port].each do |param|
      unless resource[param]
        raise Puppet::Error, "Missing required parameter '#{param}'"
      end
    end
  end

  def attempt_connection
    begin
      s = TCPSocket.new(resource[:host], resource[:port])
      s.close
      true
    rescue Errno::ECONNREFUSED => e
      Puppet.notice "Unable to establish TCP connection to '#{connection_description}'; #{e}"
      false
    end
  end

  def connection_description
    "#{resource[:host]}:#{resource[:port]}"
  end

  def connection_type
    "TCP"
  end
end