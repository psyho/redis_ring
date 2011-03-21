$:.push File.expand_path("../../lib", __FILE__)

require 'rspec'
require 'mocha'

require 'simplecov'
SimpleCov.start

require 'redis_ring'

def require_fake(name)
  require File.expand_path("../fakes/fake_#{name}", __FILE__)
end

require_fake 'master_rpc'
require_fake 'slave_rpc'
require_fake 'process_manager'
require_fake 'zookeeper_connection'
require_fake 'node_provider'
require_fake 'http_client'

require File.expand_path('../cluster_builder', __FILE__)

RSpec.configure do |c|
  c.color_enabled = true
  c.mock_with :mocha
end
