class ClusterBuilder

  def initialize
    yield self
  end

  def nodes
    @nodes ||= {}
  end

  def node(node_id)
    nodes[node_id] ||= NodeBuilder.new(node_id, self)
  end

  def node_ids
    return nodes.keys.sort
  end

  def start_shard(node_id, shard_number)
    start_shard_callbacks.each do |block|
      block.call(node_id, shard_number)
    end
  end

  def stop_shard(node_id, shard_number)
    stop_shard_callbacks.each do |block|
      block.call(node_id, shard_number)
    end
  end

  def on_start_shard(&block)
    start_shard_callbacks << block
  end

  def on_stop_shard(&block)
    stop_shard_callbacks << block
  end

  def start_shard_callbacks
    @start_shard_callbacks ||= []
  end

  def stop_shard_callbacks
    @stop_shard_callbacks ||= []
  end

  def fake_provider
    @fake_provider ||= FakeNodeProvider.new(self)
  end

  def fake_connection
    @fake_connection ||= FakeConnection.new(self)
  end

  class FakeNodeProvider
    def initialize(cluster_builder)
      @cluster_builder = cluster_builder
      @count = 0
    end

    def new(host, port)
      result = @cluster_builder.nodes.detect{|_, node| node.get.host == host && node.get.port == port }
      return result[1].get if result
      return @cluster_builder.node("unknown-node-#{@count += 1}").host(host).port(port).reachable(false).get
    end
  end

  class FakeConnection
    def initialize(cluster_builder)
      @cluster_builder = cluster_builder
    end

    def node_data(node_id)
      return nil unless @cluster_builder.nodes.key?(node_id)
      node = @cluster_builder.node(node_id).get
      return {"host" => node.host, "port" => node.port}
    end
  end

  class NodeBuilder
    def initialize(node_id, cluster_builder)
      @node_id = node_id
      @joined = true
      @running_shards = []
      @available_shards = {}
      @host = "localhost"
      @port = 6400
      @reachable = true
      @cluster_builder = cluster_builder
    end

    def host(str)
      @host = str
      self
    end

    def port(int)
      @port = int
      self
    end

    def reachable(bool)
      @reachable = bool
      self
    end

    def joined(bool)
      @joined = bool
      self
    end

    def running_shards(arr)
      @running_shards = arr
      self
    end

    def running_shard(shard)
      @running_shards << shard unless @running_shards.include?(shard)
      self
    end

    def not_running_shard(shard)
      @running_shards.delete(shard)
      self
    end

    def available_shards(hash)
      @available_shards = hash
      self
    end

    def available_shard(shard, timestamp)
      @available_shards[shard] = timestamp
      self
    end

    def not_available_shard(shard)
      @available_shards.delete(shard)
      self
    end

    def load_properties(node)
      node.load(props)
    end

    def props
      {
        :host => @host,
        :port => @port,
        :node_id => @node_id,
        :running_shards => @running_shards,
        :available_shards => @available_shards,
        :joined => @joined,
        :reachable => @reachable,
        :cluster_builder => @cluster_builder
      }
    end

    def get
      @node ||= FakeNode.new(self)
    end
  end

  class FakeNode

    attr_reader :host, :port, :node_id

    def initialize(builder)
      @builder = builder
      @builder.load_properties(self)
    end

    def load(opts)
      @joined = opts[:joined]
      @running_shards = opts[:running_shards]
      @available_shards = opts[:available_shards]
      @reachable = opts[:reachable]
      @host = opts[:host]
      @port = opts[:port]
      @node_id = opts[:node_id]
      @cluster_builder = opts[:cluster_builder]
    end

    def joined?
      @joined
    end

    def available_shards
      @available_shards
    end

    def running_shards
      @running_shards
    end

    def start_shard(shard_number)
      ensure_reachable
      @running_shards << shard_number unless @running_shards.include?(shard_number)
      @cluster_builder.start_shard(@node_id, shard_number)
    end

    def stop_shard(shard_number)
      ensure_reachable
      @running_shards.delete(shard_number)
      @cluster_builder.stop_shard(@node_id, shard_number)
    end

    def update_status!
      @builder.load_properties(self)
      ensure_reachable
    end

    protected

    def ensure_reachable
      raise "Node #{@node_id} #{@host}:#{@port} is not reachable!" unless @reachable
    end
  end

end
