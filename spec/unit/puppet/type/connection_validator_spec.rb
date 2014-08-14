#!/usr/bin/env bundle exec rspec

require 'spec_helper'
require 'puppet_spec/http/test_server'

RSpec.describe Puppet::Type.type(:connection_validator) do

  it 'does not log warning about multiple default providers' do
    expect(Puppet).to_not receive(:warning).with(/Found multiple default providers/)
    described_class.defaultprovider
  end

  it 'has tcp as default provider' do
    expect(described_class.defaultprovider).to be(Puppet::Type::Connection_validator::ProviderTcp)
  end

  describe 'supported providers' do
    subject { described_class.suitableprovider.map(&:name) }
    it { is_expected.to include(:http) }
    it { is_expected.to include(:tcp) }
  end

end
