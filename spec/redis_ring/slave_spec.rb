require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Slave do
  before(:each) do
    @slave = RedisRing::Slave.new(@configuration = RedisRing::Configuration.new,
                                  @master_rpc = FakeMasterRPC.new,
                                  @process_manager = FakeProcessManager.new)
    @slave.node_id = "some-node"
    @slave.current_master_host = "localhost"
    @slave.current_master_port = 6400
  end

  it "should not be joined initially" do
    @slave.should_not be_joined
  end

  it "should be joined after joining" do
    @slave.join
    @slave.should be_joined
  end

  it "should tell master to load this node on joining" do
    @slave.join

    @master_rpc.connection(@slave.current_master_host, @slave.current_master_port).nodes_loaded.should == [@slave.node_id]
  end

  it "should start shard when asked to" do
    @slave.start_shard(0)

    @process_manager.started_shards.map(&:shard_number).should == [0]
  end

  it "should not start shard if already started" do
    @slave.start_shard(0)
    @slave.start_shard(0)

    @process_manager.started_shards.map(&:shard_number).should == [0]
  end

  it "should add shard to running when started" do
    @slave.start_shard(0)
    @slave.start_shard(2)
    @slave.start_shard(4)

    @slave.running_shards.keys.sort.should == [0, 2, 4]
  end

  it "should stop shard if it is running" do
    @slave.start_shard(0)
    @slave.stop_shard(0)

    @process_manager.stopped_shards.map(&:shard_number).should == [0]
  end

  it "should do nothing if requested to stop a shard that is not running" do
    @slave.stop_shard(0)

    @process_manager.stopped_shards.should be_empty
  end

  it "it should remove stopped shard from running shards" do
    @slave.start_shard(0)
    @slave.start_shard(1)
    @slave.stop_shard(0)

    @slave.running_shards.keys.sort.should == [1]
  end

  it "should return status" do
    5.times { |n| @slave.start_shard(n) }
    @slave.join

    status = @slave.status

    status[:joined].should be_true
    status[:running_shards].should == (0..4).to_a
    status.key?(:available_shards).should be_true
  end

end
