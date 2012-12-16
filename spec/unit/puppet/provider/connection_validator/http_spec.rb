require 'spec_helper'
require 'puppet'
require 'thin'

TestPort = 9090

class HttpConnTestState
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


  def initialize
    @port = TestPort
    @server = Thin::Server.new("localhost", @port, self, :backend => Backend)
    @num_conns = 0
  end

  def call(arg)
    # This is a callback for handling web requests; it's expected to return a
    # a Rack-compatible response ([code, headers, body]).  For our purposes, all
    # that really matters is that it returns a 200/OK so that the production
    # code will consider it a successful HTTP request
    [200, nil, ""]
  end

  def start_server(start_server_delay = 0)
    # this sucks, and there's probably a better way to deal with it... but it
    # appears that calling 'start' can leave you in a slightly messed up
    # state if the port isn't available when you call it?(!)  In any case, adding
    # a sleep here seems to assure that the server will be started cleanly.
    sleep(1)
    Thread.new {
      sleep(start_server_delay)
      @server.start
    }
    if (start_server_delay == 0)
      wait_for_server
    end
  end

  def wait_for_server
    num_retries = 0
    while ! (@server.running?)
      num_retries += 1
      if (num_retries) > 8
        raise RuntimeError, "Waiting for server to start, never started!"
      end
      sleep 0.25
    end
  end

  def stop_server
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
end



provider_class = Puppet::Type.type(:connection_validator).provider(:http)
describe provider_class do
  before(:all) {
    @state = HttpConnTestState.new
  }

  let(:resource) {
      Puppet::Type::Connection_validator.new({
          :name     => "hi",
          :provider => "http",
          :host     => "localhost",
          :port     => TestPort,
          :timeout  => 0,
      })
  }

  def check_for_success(resource, start_server_delay = 0)
    num_conns = @state.num_conns
    @state.start_server(start_server_delay)
    provider = described_class.new(resource)
    provider.exists?.should be_true
    @state.stop_server
    @state.num_conns.should == num_conns + 1
  end

  it "should fail if both url and host are specified" do
    resource[:url]  = "http://localhost/foo"
    resource[:host] = "localhost"
    provider = described_class.new(resource)
    expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
  end

  it "should fail if both url and scheme are specified" do
    resource[:url]    = "https://localhost/foo"
    resource[:scheme] = "https"
    provider = described_class.new(resource)
    expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
  end

  it "should fail if both url and port are specified" do
    resource[:url]  = "http://localhost/foo"
    resource[:port] = TestPort
    provider = described_class.new(resource)
    expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
  end

  it "should fail if both url and path are specified" do
    resource[:url]  = "http://localhost/foo"
    resource[:path] = "/index.cfm"
    provider = described_class.new(resource)
    expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
  end

  it "should fail if both url and host are specified" do
    resource[:url]  = "http://localhost/foo"
    resource[:host] = "localhost"
    provider = described_class.new(resource)
    expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
  end

  it "should fail when there is no server listening on the port" do
    provider = described_class.new(resource)
    provider.exists?.should be_false
    expect { provider.create }.to raise_error(Puppet::Error, /Unable to establish http conn/)
  end

  it "should succeed when host/port/path are specified and the server is up" do
    check_for_success(resource)
  end

  it "should succeed when url is specified and the server is up" do
    resource = Puppet::Type::Connection_validator.new({
        :name     => "hi",
        :provider => "http",
        :url      => "http://localhost:9090/foo",
    })
    check_for_success(resource)
  end

  it "should succeed when a https url is specified and the server is up" do
    resource = Puppet::Type::Connection_validator.new({
        :name     => "hi",
        :provider => "http",
        :url      => "https://localhost:9090/foo",
    })

    check_for_success(resource)
  end

  it "should succeed when a https scheme is specified and the server is up" do
    resource[:scheme] = "https"
    check_for_success(resource)
  end

  it "should not retry if timeout is 0" do
    resource[:timeout] = 0
    provider = described_class.new(resource)
    provider.exists?.should be_false
    logs.select { |l| l.message =~ /Failed to connect to '[^']+'; sleeping/ }.length.should == 0
  end

  it "should retry if timeout is not 0" do
    resource[:timeout] = 5
    provider = described_class.new(resource)
    provider.exists?.should be_false
    logs.select { |l| l.message =~ /Failed to connect to '[^']+'; sleeping/ }.length.should_not == 0
  end

  it "should succeed if server comes online within timeout" do
    resource[:timeout] = 10
    check_for_success(resource, 2)
    logs.select { |l| l.message =~ /Failed to connect to '[^']+'; sleeping/ }.length.should_not == 0
  end

end
