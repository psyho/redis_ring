module RedisRing

  class Slave

    attr_accessor :current_master_host, :current_master_port, :node_id
    attr_reader :configuration, :master_rpc, :process_manager
    attr_reader :running_shards

    def initialize(configuration, master_rpc, process_manager)
      @configuration = configuration
      @master_rpc = master_rpc
      @process_manager = process_manager
      @joined = false
      @running_shards = {}
    end

    def joined?
      @joined
    end

    def available_shards
      available_shards = {}
      configuration.ring_size.times do |shard_no|
        shard_conf = ShardConfig.new(shard_no, configuration)
        timestamp = [shard_conf.db_mtime, shard_conf.aof_mtime].compact.max
        available_shards[shard_no] = timestamp if timestamp
      end
      return available_shards
    end

    def status
      { :joined => joined?, :running_shards => running_shards.keys, :available_shards => available_shards }
    end

    def join
      puts "JOINING CLUSTER"
      @joined = true
      master_rpc.connection(current_master_host, current_master_port).node_loaded(node_id)
    end

    def start_shard(shard_number)
      puts "STARTING SHARD #{shard_number}"
      return if running_shards.include?(shard_number)
      shard_conf = ShardConfig.new(shard_number, configuration)
      shard = running_shards[shard_number] = Shard.new(shard_conf)
      process_manager.start_shard(shard)
    end

    def stop_shard(shard_number)
      puts "STOPPING SHARD #{shard_number}"
      process_manager.stop_shard(shard)
      running_shards.delete(shard_number)
    end

    def sync_shard_with(shard_number, host, port)
    end

  end

end
