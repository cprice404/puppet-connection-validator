# Here are some examples of how you can validate an TCP connection

# This will attempt to establish a TCP connection to the host
# 'postgres.foo.com' on port 5432, and will fail quickly if the connection
# can't be made.
connection_validator { 'postgres_connection':
    provider => 'tcp',
    host     => 'postgres.foo.com',
    port     => 5432,
}

# This will attempt to establish a TCP connection to the host 'puppetdb.foo.com'
# on port 8080.  It will retry every 2 seconds for a maximum period of
# 10 seconds.  After that, if a successful request has not been made, the
# resource will fail.
connection_validator { 'puppetdb_connection':
    provider       => 'tcp',
    host           => 'puppetdb.foo.com',
    port           => 8080,
    retry_interval => 2,
    timeout        => 10,
}
