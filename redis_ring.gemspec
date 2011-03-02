# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis_ring/version"

Gem::Specification.new do |s|
  s.name        = "redis_ring"
  s.version     = RedisRing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Pohorecki"]
  s.email       = ["adam@pohorecki.pl"]
  s.homepage    = "http://github.com/psyho/redis_ring"
  s.summary     = %q{A simplistic solution to redis sharding}
  s.description = %q{RedisRing is a solution to run multiple small Redis instances intead of a single large one.}

  s.rubyforge_project = "redis_ring"

  s.add_dependency 'sinatra'
  s.add_dependency 'json'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
