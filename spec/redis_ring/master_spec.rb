require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Master do

  describe :is_master do
    before(:each) do
      @master = RedisRing::Master.new(nil, nil, nil)
    end

    it "should not be master initially" do
      @master.is_master?.should be_false
    end

    it "should be master after became_master event" do
      @master.became_master

      @master.is_master?.should be_true
    end

    it "should not be master after no_longer_is_master" do
      @master.became_master
      @master.no_longer_is_master

      @master.is_master?.should be_false
    end
  end

  describe :reassign_shards do
    before(:each) do
      @builder = ClusterBuilder.new do |b|
        b.node("node0").port(6401)
        b.node("node1").port(6402)
        b.node("node2").port(6403)
        b.node("node3").port(6404)
        b.node("node4").port(6405)
      end

      @started_shards = []
      @stopped_shards = []
      @shards_per_node = Hash.new(0)
      @stopped_on_node = Hash.new(0)

      @builder.on_start_shard do |node_id, shard_no|
        @started_shards << shard_no
        @shards_per_node[node_id] += 1
      end

      @builder.on_stop_shard do |node_id, shard_no|
        @stopped_shards << shard_no
        @stopped_on_node[node_id] += 1
      end

      @master = RedisRing::Master.new(@builder.fake_connection, 16, @builder.fake_provider)
      @master.became_master
    end

    it "should assign shards fairly to all nodes" do
      @master.nodes_changed(@builder.node_ids)

      @started_shards.sort.should == (0...16).to_a
      @shards_per_node.values.reduce(&:+).should == 16
      @shards_per_node.values.uniq.sort.should == [3, 4]
    end

    it "should do nothing when is not a master" do
      @master.no_longer_is_master

      @master.nodes_changed(@builder.node_ids)

      @started_shards.should be_empty
    end

    it "should not reassign anything when nothing has changed" do
      @master.nodes_changed(@builder.node_ids)
      @started_shards = []
      @shards_per_node = Hash.new(0)

      @master.nodes_changed(@builder.node_ids)

      @started_shards.should be_empty
    end

    it "should ignore not joined nodes, without assigning their portion o shards elsewhere" do
      @builder.node("node0").joined(false)

      @master.nodes_changed(@builder.node_ids)

      @started_shards.size.should == 12
      @shards_per_node["node0"].should == 0
    end

    it "should assign shards to the freshly joined node" do
      @builder.node("node0").joined(false)
      @master.nodes_changed(@builder.node_ids)
      @started_shards = []
      @shards_per_node = Hash.new(0)
      @builder.node("node0").joined(true)

      @master.node_joined("node0")

      @started_shards.size.should == 4
      @shards_per_node["node0"].should == 4
    end

    it "should not over-asign nodes if they are already running some shards" do
      @builder.node("node0").running_shards([0, 1, 2])
      @builder.node("node1").running_shards([3, 4, 5, 6])

      @master.nodes_changed(@builder.node_ids)

      @started_shards.size.should == 16 - 7
      ((0..6).to_a - @started_shards).should == (0..6).to_a
      @shards_per_node["node0"].should == 1
      @shards_per_node["node1"].should == 0
    end

    it "should reassign the shards that belonged to a node that crashed" do
      @master.nodes_changed(@builder.node_ids)
      @started_shards = []
      @shards_per_node = Hash.new(0)
      @builder.nodes.delete("node0")

      @master.nodes_changed(@builder.node_ids)

      @started_shards.size.should == 4
      @shards_per_node.values.uniq.should == [1]
    end

    it "should stop shards that are running on more than one node" do
      @builder.node("node0").running_shards([0, 1, 2])
      @builder.node("node1").running_shards([0, 1])
      @builder.node("node2").running_shards([0, 2])

      @master.nodes_changed(@builder.node_ids)

      @stopped_shards.uniq.sort.should == [0, 1, 2]
      @stopped_shards.size.should == 4
      ([0, 1, 2] - @started_shards).should == [0, 1, 2]
    end

  end

  describe :status do
    before(:each) do
      @builder = ClusterBuilder.new do |b|
        b.node("node0").host("a.example.com").port(6400)
        b.node("node1").host("b.example.com").port(6400)
      end

      @master = RedisRing::Master.new(@builder.fake_connection, 8, @builder.fake_provider)
      @master.became_master
      @master.nodes_changed(@builder.node_ids)
    end

    it "should return the ring_size" do
      @master.status[:ring_size].should == 8
    end

    it "should return the shards" do
      @master.status[:shards].should == {
        0 => { :host => "a.example.com", :port => 6401, :status => :running },
        1 => { :host => "a.example.com", :port => 6402, :status => :running },
        2 => { :host => "a.example.com", :port => 6403, :status => :running },
        3 => { :host => "a.example.com", :port => 6404, :status => :running },
        4 => { :host => "b.example.com", :port => 6405, :status => :running },
        5 => { :host => "b.example.com", :port => 6406, :status => :running },
        6 => { :host => "b.example.com", :port => 6407, :status => :running },
        7 => { :host => "b.example.com", :port => 6408, :status => :running }
      }
    end

  end

end
