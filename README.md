puppet-connection-validator
===========================

A puppet module for validating network connections.

This module doesn't actually do anything, except possibly cause your runs to
fail.  :)

The goal of this module is to provide you with a resource type that you can
use to validate network connections.  The value of this is mostly for
ordering your catalog or establishing dependencies such that certain actions
will only be taken after you've successfully tested the network connection.

So, for example, if your manifest contains some configuration for a web app
that is running on a node, and that configuration includes setting up a
connection to a Postgres database on another server, then you might not want
to apply that configuration until you know for sure that the postgres server
is up and running and accepting connections.  In such a case, you could
add a `connection_validator` resource to your manifest to check the
postgres connection, and then use a `before` or `require` to make sure that your
other resources don't get applied if the postgres connection can't be established.

The type includes parameters for setting a `retry_interval` and a `timeout`,
so that you have control over how many times the connection is attempted
before giving up.

For examples, please see the files in `test`.