#!/usr/bin/env ruby

$:.push File.expand_path("../../lib", __FILE__)

require 'redis_ring'

config = RedisRing::Configuration.new(:base_directory => '/tmp/redis-ring-test', :base_port => 6500, :ring_size => 4)
app = RedisRing::Application.new(config)

app.start

while not RedisRing::WebInterface.master
  sleep(0.1)
end

app.slave.join
sleep(1)

passed = (app.slave.running_shards.keys == (0..3).to_a)

app.stop
app.wait

unless passed
  puts "Integration Test Failed!"
  exit(1)
end
