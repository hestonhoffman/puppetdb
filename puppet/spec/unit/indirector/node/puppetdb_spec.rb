#!/usr/bin/env rspec

require 'spec_helper'

require 'puppet/indirector/node/puppetdb'
require 'puppet/util/puppetdb/command_names'
require 'json'
require 'date'
require 'time'

describe Puppet::Node::Puppetdb do

  CommandDeactivateNode = Puppet::Util::Puppetdb::CommandNames::CommandDeactivateNode

  before :each do
    Puppet::Node.indirection.stubs(:terminus).returns(subject)
  end

  let(:node) { "something.example.com" }
  let(:producer_timestamp) { Puppet::Util::Puppetdb.to_wire_time(Time.now) }

  def destroy
    Puppet::Node.indirection.destroy(node)
  end

  describe "#destroy" do
    let(:response) { Net::HTTPOK.new('1.1', 200, 'OK') }
    let(:http)     { mock 'http' }
    before :each do
      Puppet::Network::HttpPool.expects(:connection).returns http
    end

    it "should POST a '#{CommandDeactivateNode}' command" do
      response.stubs(:body).returns '{"uuid": "a UUID"}'
      http.expects(:post).with do |uri,body,headers|
        req = JSON.parse(body)
        req["certname"] == node &&
          extract_producer_timestamp(req) <= Time.now.to_i
      end.returns response

      destroy
    end

    it "should log a deprecation warning if one is returned from PuppetDB" do
      response['x-deprecation'] = 'A horrible deprecation warning!'
      response.stubs(:body).returns '{"uuid": "a UUID"}'

      Puppet.expects(:deprecation_warning).with do |msg|
        msg =~ /A horrible deprecation warning!/
      end

      http.stubs(:post).returns response

      destroy
    end
  end
end
