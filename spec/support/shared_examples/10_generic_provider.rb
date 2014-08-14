RSpec.shared_examples "generic provider" do

  describe ':timeout' do
    let(:retry_interval) { "0.1" }

    before :each do
      allow(provider).to receive(:attempt_connection).and_return(false)
      provider.exists?
    end

    [nil, 0].each do |t|
      context t.inspect do
        let(:timeout) { t }
        it 'makes only one connection attempt' do
          expect(provider).to have_received(:attempt_connection).once
        end

        it 'logs a warning' do
          expect(logs.grep(/Failed to connect to '[^']+'/).size).to eq(1)
        end
      end
    end

    context 'non-zero value (including string)' do
      let(:timeout) { "1" }
      it 'retries' do
        expect(provider).to have_received(:attempt_connection).at_least(2).times
      end

      it 'logs warning with note that it will retry' do
        expect(logs.grep(/Failed to connect to '[^']+'; sleeping/)).to_not be_empty
      end
    end
  end

  describe ':retry_interval' do
    let(:timeout) { 2 }

    before :each do
      allow(provider).to receive(:sleep) { |n| Kernel.sleep(n) }
      provider.exists?
    end

    context 'if set explicitly' do
      let(:retry_interval) { "5" }
      it "sleeps for retry_interval seconds between requests" do
        expect(provider).to have_received(:sleep).with(5.0).once
      end
    end

    describe 'default' do
      it 'is 2 seconds' do
        expect(provider).to have_received(:sleep).with(2.0).once
      end
    end
  end

  context 'monitored service' do
    let(:timeout) { 5 }

    around :each do |example|
      @server.start(server_start_delay)
      example.run
      @server.stop
    end

    context 'is already up' do
      let(:server_start_delay) { 0 }

      it 'is true' do
        expect(provider.exists?).to be true
      end

      it 'does not log any errors' do
        provider.exists?
        expect(logs.grep(/Failed to connect to '[^']+'/)).to be_empty
      end
    end

    context 'comes alive within timeout' do
      let(:server_start_delay) { 2 }
      it 'should succeed' do
        expect(provider.exists?).to be true
        expect(logs.grep(/Failed to connect to '[^']+'; sleeping/)).to_not be_empty
      end
    end

    context 'comes alive after timeout' do
      let(:timeout) { 1 }
      let(:server_start_delay) { timeout + 2 }
      it 'should fail' do
        expect(provider.exists?).to be false
      end
    end
  end

  describe '#create' do
    it 'always fails if called' do
      expect { provider.create }.to raise_error(Puppet::Error, /Unable to establish (TCP|HTTP) conn/)
    end
  end

end

