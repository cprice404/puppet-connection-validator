require 'net/http'
require 'puppet_x/connection_validator'

Puppet::Type.type(:connection_validator).provide(:http) do
  include PuppetX::ConnectionValidator

  # If there were a way to specify a docstring for a provider, I'd
  # do it here.
  #-----------------------------------------------------------------------------
  # HTTP provider for connection_validator type
  #
  # This provider validates that a successful HTTP request can be issued to
  # a specified host or URL.  To use this provider, you may either provide the
  # 'url' parameter, or some combination of the 'host'/'port'/'path' parameters.
  #
  # If you specify a 'url' parameter, the provider will simply issue
  # a GET request to that URL.
  #
  # If you specify the 'host' / 'port' / 'path', parameters, a URI will be
  # constructed (http://<host>:<port>/<path>) and the provider will issue
  # a GET request to that URI.  'host' will default to 'localhost',
  # 'port' will default to '80', and 'path' will default to '/'.
  #
  # In all cases, the request will be considered successful if the server returns
  # an HTTP response code of '200 OK'.
  #-----------------------------------------------------------------------------


  private

  def validate
    if resource["url"]
      if (resource["scheme"] or resource["host"] or resource["port"] or resource["path"])
        raise Puppet::Error, "If you specify the 'url' parameter, you must " +
            "not pass any of the 'scheme'/'host'/'port'/'path' parameters."
      end
    end
  end

  def uri
    return @uri if @uri
    if resource["url"]
      return URI(resource["url"])
    end

    scheme = resource["scheme"] || "http"
    host = resource["host"] || "localhost"
    port = resource["port"] || 80
    path = (resource["path"] || "").gsub(/^\//, "")

    @uri = URI("#{scheme}://#{host}:#{port}/#{path}")
  end

  # Utility method; attempts to make an http connection.
  # This is abstracted out into a method so that it can be called multiple times
  # for retry attempts.
  #
  # @return true if the connection is successful, false otherwise.
  def attempt_connection
    begin
      response = Net::HTTP.get_response(uri)
      unless response.code == "200"
        Puppet.notice "HTTP request (#{uri}) failed: (#{response.code} #{response.body})"
        return false
      end
      return true
    rescue Errno::ECONNREFUSED => e
      Puppet.notice "Unable to establish HTTP connection to '#{uri}'; #{e}"
      return false
    end
  end

  def connection_type
    "HTTP"
  end

  def connection_description
    uri
  end
end
