require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::ShardConfig do
  it "should render redis config with default config variables" do
    config = RedisRing::Configuration.new
    shard_config = RedisRing::ShardConfig.new(0, config)

    redis_conf = shard_config.render

    puts redis_conf

    redis_conf.should include((config.base_port + 1).to_s)
    redis_conf.should include(config.base_directory)
  end
end
