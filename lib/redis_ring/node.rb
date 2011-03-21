module RedisRing

  class NodeProvider

    attr_reader :slave_rpc

    def initialize(slave_rpc)
      @slave_rpc = slave_rpc
    end

    def new(host, port)
      Node.new(slave_rpc.connection(host, port))
    end

  end

  class Node

    attr_reader :slave_rpc

    def initialize(slave_rpc)
      @slave_rpc = slave_rpc
    end

    def update_status!
      status_hash = slave_rpc.status
      @joined = status_hash["joined"]
      @running_shards = status_hash["running_shards"] || []
      @available_shards = keys_to_i(status_hash["available_shards"] || {})
    end

    def joined?
      @joined
    end

    def start_shard(shard_number)
      running_shards << shard_number
      slave_rpc.start_shard(shard_number)
    end

    def stop_shard(shard_number)
      running_shards.delete(shard_number)
      slave_rpc.stop_shard(shard_number)
    end

    def running_shards
      @running_shards ||= []
    end

    def available_shards
      @available_shards ||= {}
    end

    protected

    def keys_to_i(hash)
      result = {}
      hash.each { |key, val| result[key.to_i] = val }
      return result
    end

  end

end
