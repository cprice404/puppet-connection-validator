#require File.expand_path('../../../util/ini_file', __FILE__)
require 'net/http'

Puppet::Type.type(:connection_validator).provide(:http) do

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

  def validate
    if resource["url"]
      if (resource["scheme"] or resource["host"] or resource["port"] or resource["path"])
        raise Puppet::Error, "If you specify the 'url' parameter, you must " +
            "not pass any of the 'scheme'/'host'/'port'/'path' parameters."
      end
    end
  end

  def exists?
    # this is horrible--Puppet ought to be calling into the provider
    # for validation as a normal part of the type/provider life cycle,
    # but I couldn't find a place where that happens so'
    # I'm calling my own validation hook here.
    validate

    start_time = Time.now
    timeout = resource[:timeout] || 0
    retry_interval = resource[:retry_interval] || 2

    uri = get_uri
    success = attempt_connection(uri)

    unless success
      while (((Time.now - start_time) < timeout) && !success)
        # It can take several seconds for the puppetdb server to start up;
        # especially on the first install.  Therefore, our first connection attempt
        # may fail.  Here we have somewhat arbitrarily chosen to retry every 10
        # seconds until the configurable timeout has expired.
        Puppet.notice("Failed to connect to '#{uri}'; sleeping #{resource["retry_interval"]} seconds before retry")
        sleep retry_interval
        success = attempt_connection(uri)
      end
    end

    unless success
      Puppet.notice("Failed to connect to '#{uri}' within timeout window of #{timeout} seconds; giving up.")
    end

    success
  end

  def create
    uri = get_uri

    # If `#create` is called, that means that `#exists?` returned false, which
    # means that the connection could not be established... so we need to
    # cause a failure here.
    raise Puppet::Error, "Unable to establish http conn to server! (#{uri})"
  end

  private
  def get_uri
    if resource["url"]
      return URI(resource["url"])
    end

    scheme = resource["scheme"] || "http"
    host = resource["host"] || "localhost"
    port = resource["port"] || 80
    path = (resource["path"] || "").gsub(/^\//, "")

    URI("#{scheme}://#{host}:#{port}/#{path}")
  end

  # Utility method; attempts to make an http connection.
  # This is abstracted out into a method so that it can be called multiple times
  # for retry attempts.
  #
  # @return true if the connection is successful, false otherwise.
  def attempt_connection(uri)
    begin
      response = Net::HTTP.get_response(uri)
      unless response.code == "200"
        Puppet.notice "HTTP request (#{uri}) failed: (#{response.code} #{response.body})"
        return false
      end
      return true
    rescue Errno::ECONNREFUSED => e
      Puppet.notice "Unable to establish http connection to '#{uri}'; #{e}"
      return false
    end

  end
end
