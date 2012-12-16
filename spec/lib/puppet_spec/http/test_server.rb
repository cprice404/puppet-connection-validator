require 'thin'

module PuppetSpec
module Http
class TestServer

  class FakeApp
    def call(arg)
    # This is a callback for handling web requests; it's expected to return a
    # a Rack-compatible response ([code, headers, body]).  For our purposes, all
    # that really matters is that it returns a 200/OK so that the production
    # code will consider it a successful HTTP request
    [200, nil, ""]
    end
  end

  class Backend < Thin::Backends::TcpServer
    def initialize(host, port, options)
      @num_conns = 0
      super(host, port)
    end

    attr_reader :num_conns

    def connection_finished(conn)
      @num_conns += 1
      super(conn)
    end
  end

  def initialize(port)
    @port = port
    @server = Thin::Server.new("localhost", @port, FakeApp.new, :backend => Backend)
    @num_conns = 0
  end


  def start(start_server_delay = 0)
    # this sucks, and there's probably a better way to deal with it... but it
    # appears that calling 'start' can leave you in a slightly messed up
    # state if the port isn't available when you call it?(!)  In any case, adding
    # a sleep here seems to assure that the server will be started cleanly.
    sleep(1)

    # Ruby doesn't let you create a thread without starting it, so we have to
    # use a lock to give us the opportunity to toggle the `abort_on_exception`
    # value before the thread really starts running code.  Otherwise exceptions
    # get swallowed and it's impossible to tell what's going on.
    lock = Mutex.new
    lock.lock
    t = Thread.new {
      lock.lock
      sleep(start_server_delay)
      @server.start
    }
    t.abort_on_exception = true
    lock.unlock
    if (start_server_delay == 0)
      wait_for_server
    end
  end


  def stop
    @server.stop
    if (@server.backend.size > 0)
      puts "Server still has #{@server.backend.size} open connections; looping until they are closed."
    end
    while (@server.backend.size > 0)
      sleep(0.001)
    end
    sleep(1)
  end

  def num_conns
    @server.backend.num_conns
  end


  private

  def wait_for_server
    num_retries = 0
    while ! (@server.running?)
      num_retries += 1
      if (num_retries) > 20
        raise RuntimeError, "Waiting for server to start, never started!"
      end
      sleep 0.25
    end
  end

end
end
end