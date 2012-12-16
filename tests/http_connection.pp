# Here are some examples of how you can validate an HTTP connection

# This will attempt an http request to http://web.foo.com:80/, and will
# fail quickly if the connection can't be made.
connection_validator { 'webserver_connection':
    provider => 'http',
    host     => 'web.foo.com',
    port     => 80,
}

# This will attempt an http request to https://web.foo.com:8080/myapp/index.html.
# If the request fails, it will retry every 2 seconds for a maximum period of
# 10 seconds.  After that, if a successful request has not been made, the
# resource will fail.
connection_validator { 'webapp_connection':
    provider       => 'http',
    url            => 'https://web.foo.com:8080/myapp/index.html',
    retry_interval => 2,
    timeout        => 10,
}

# This is another way to express the same thing as the previous example:
connection_validator { 'webapp2_connection':
    provider        => 'http',
    scheme          => 'https',
    host            => 'web.foo.com',
    port            => 8080,
    path            => '/myapp/index.html',
    retry_interval  => 2,
    timeout         => 10,
}
