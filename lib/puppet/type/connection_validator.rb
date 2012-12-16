Puppet::Type.newtype(:connection_validator) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:host) do
    desc 'The hostname or IP address to connect to.  Defaults to "localhost".'
  end

  newparam(:port) do
    desc 'The port to connect on.  Individual providers may provide ' +
        'default values.'
  end

  newparam(:scheme) do
    desc 'Used only by the HTTP provider; valid values are "http" and "https".'
  end

  newparam(:path) do
    desc 'Used only by the HTTP provider; the path to request from the HTTP ' +
        'server to validate the connection. (e.g. "/index.html")'
  end

  newparam(:url) do
    desc 'Used only by the HTTP provider; may be used to specify the full URL ' +
        'for validating the connection (replacing the :scheme, :host, :port, ' +
        'and :path params.)  Defaults to "/".'
  end

  newparam(:timeout) do
    desc "The maximum amount of time (in seconds) to continue retrying the " +
          "connection before failing.  A value of '0' means that we should " +
          "only attempt the connection once, with no retries."
  end

  newparam(:retry_interval) do
    desc 'The interval of time (in seconds) to wait between each connection '
          'attempt.'
  end
end
