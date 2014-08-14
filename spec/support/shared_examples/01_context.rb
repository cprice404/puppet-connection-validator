RSpec.shared_context "provider" do

  ServerPort = 9090

  # Default values passed to validator provider. These are overridden by individual test
  # cases as required.
  let(:port) { ServerPort }
  let(:host) { 'localhost' }
  let(:timeout) { 1 }
  let(:retry_interval) { nil }
  let(:url) { nil }
  let(:scheme) { nil }
  let(:path) { nil }

  # Default delay 
  let(:default_args) do
    { :name => "hi", :provider => provider_name, :host => host, :port => port, :timeout => timeout, :retry_interval => retry_interval, :url => url, :scheme => scheme, :path => path }
  end

  let(:provider) do
    args = default_args.reject { |k,v| v.nil? }
    described_class.new(Puppet::Type::Connection_validator.new(args))
  end

  before(:all) do
    @server = PuppetSpec::Http::TestServer.new(ServerPort)
    # Thin::Logging.silent = true
  end

end

