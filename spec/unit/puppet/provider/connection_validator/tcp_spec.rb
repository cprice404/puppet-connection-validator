#!/usr/bin/env bundle exec rspec

require 'spec_helper'
require 'puppet_spec/http/test_server'

RSpec.describe Puppet::Type.type(:connection_validator).provider(:tcp) do

  include_context 'provider'

  let(:provider_name) { 'tcp' }

  describe ':url' do
    let(:url) { 'http://localhost' }
    it 'is not allowed' do
      expect { provider.exists? }.to raise_error(Puppet::Error, /This provider does not support the parameter/)
    end
  end

  describe ':scheme' do
    let(:scheme) { 'https' }
    it 'is not allowed' do
      expect { provider.exists? }.to raise_error(Puppet::Error, /This provider does not support the parameter/)
    end
  end

  describe ':path' do
    let(:path) { '/index.cfm' }
    it 'is not allowed' do
      expect { provider.exists? }.to raise_error(Puppet::Error, /This provider does not support the parameter/)
    end
  end

  describe ':port' do
    let(:port) { nil }
    it 'is required' do
      expect { provider.exists? }.to raise_error(Puppet::Error, /Missing required parameter/)
    end
  end

  include_examples 'generic provider'
end
