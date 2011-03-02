$:.push File.expand_path("../lib", __FILE__)

require 'redis_ring'

RSpec.configure do |c|
  c.color_enabled = true
  c.mock_with :mocha
end
