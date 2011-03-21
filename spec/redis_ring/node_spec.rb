require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Node do

  before(:each) do
    @node = RedisRing::Node.new(@slave_rpc = FakeSlaveRPC.new.connection("some_host", 666), "some_host", 666)

    @slave_rpc.status = {
      "joined" => true,
      "running_shards" => [1, 2, 3],
      "available_shards" => { "1" => 1233, "2" => 4566 }
    }
  end

  it "should return some sane defults when calling without update_status!" do
    @node.joined?.should be_false
    @node.running_shards.should == []
    @node.available_shards.should == {}
  end

  it "should only update the data when update_status! is called" do
    @node.update_status!

    @node.joined?.should be_true
    @node.running_shards.should == [1, 2, 3]
    @node.available_shards.should == {1 => 1233, 2 => 4566}
  end

  it "should reflect start_shard in running shards without calling update_status!" do
    @node.start_shard(9)

    @node.running_shards.should == [9]
  end

  it "should send rpc to slave on start_shard" do
    @node.start_shard(9)

    @slave_rpc.started_shards.should == [9]
  end

  it "should reflect stop_shard in running shards without calling update_status!" do
    @node.update_status!
    @node.stop_shard(3)

    @node.running_shards.should == [1, 2]
  end

  it "should send rpc to slave on start_shard" do
    @node.stop_shard(9)

    @slave_rpc.stopped_shards.should == [9]
  end
end
