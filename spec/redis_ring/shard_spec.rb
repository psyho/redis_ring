require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Shard do

  describe "possible statuses" do
    before(:each) do
      @shard = RedisRing::Shard.new(RedisRing::ShardConfig.new(0, RedisRing::Configuration.new))
      @task = stub(:start => true, :stop => true)
      @shard.shard_config.stubs(:save)
      @shard.stubs(:fork_redis_server => @task)
      @shard.stubs(:send_kill_signal)
    end

    it "should be stopped initially" do
      @shard.status.should == :stopped
    end

    it "should be running if started and alive" do
      @task.stubs(:running? => true)
      @shard.start

      @shard.status.should == :running
    end

    it "should be stopping if started then stopped but still alive" do
      @task.stubs(:running? => true)
      @shard.start
      @shard.stop

      @shard.status.should == :stopping
    end

    it "should be stopped if started then stopped and not alive" do
      @task.stubs(:running? => false)
      @shard.start
      @shard.stop

      @shard.status.should == :stopped
    end

    it "should be dead if started but not alive" do
      @task.stubs(:running? => false)
      @shard.start

      @shard.status.should == :dead
    end
  end

end
