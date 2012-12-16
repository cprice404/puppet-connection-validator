require 'spec_helper'
require 'puppet_spec/http/test_server'


# TODO: should probably make this configurable or random
TestPort = 9090

provider_class = Puppet::Type.type(:connection_validator).provider(:http)
describe provider_class do
  before(:all) {
    @server = PuppetSpec::Http::TestServer.new(TestPort)
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
    num_conns = @server.num_conns
    @server.start(start_server_delay)
    provider = described_class.new(resource)
    provider.exists?.should be_true
    @server.stop
    @server.num_conns.should == num_conns + 1
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
