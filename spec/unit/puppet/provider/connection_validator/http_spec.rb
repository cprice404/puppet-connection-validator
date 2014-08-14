#!/usr/bin/env bundle exec rspec

require 'spec_helper'
require 'puppet_spec/http/test_server'


RSpec.describe Puppet::Type.type(:connection_validator).provider(:http) do

  include_context 'provider'

  let(:provider_name) { 'http' }

  describe ':url' do
    let(:url) { 'http://localhost' }
    let(:host) { nil }
    let(:port) { nil }

    { host: 'localhost', scheme: 'https', port: 999, path: '/index.cfn' }.each do |property, value|
      describe 'is mutually exclusive to' do
        let(property) { value }
        specify property do
          expect { provider.exists? }.to raise_error(Puppet::Error, /If you specify the 'url' parameter/)
        end
      end
    end

    context 'remote is up' do

      around :each do |example|
        @server.start(0)
        example.run
        @server.stop
      end

      describe 'http uri' do
        let(:url) { 'http://localhost:9090/foo' }
        it { expect(provider.exists?).to be true }
      end

      describe 'https uri', pending: 'test server does not support SSL' do
        let(:url) { 'https://localhost:9090/foo' }
        it { expect(provider.exists?).to be true }
      end
    end
  end

  include_context 'generic provider'
 end
