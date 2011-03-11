require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Application do

  describe "#shards_hash" do
    before(:each) do
      RedisRing::Shard.any_instance.stubs(:fork_redis_server => stub(:start => true, :stop => true, :running? => true))
      RedisRing::ShardConfig.any_instance.stubs(:save)
      RedisRing::ShardConfig.any_instance.stubs(:alive? => true)

      @application = RedisRing::Application.new(RedisRing::Configuration.new)
      @application.start
    end

    it "should return all shards" do
      shard_hash = @application.shards_hash

      shard_hash[:count].should == @application.configuration.ring_size
      shard_hash[:shards].size.should == @application.configuration.ring_size
    end
  end

end
