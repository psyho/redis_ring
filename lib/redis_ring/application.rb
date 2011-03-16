module RedisRing

  class Application

    attr_reader :shards, :configuration, :process_manager, :zookeeper_observer, :master

    def initialize(configuration)
      @configuration = configuration
      @process_manager = ProcessManager.new
      @master = Master.new
      @zookeeper_observer = ZookeeperObserver.new(configuration, master)
      @shards = {}
    end

    def start
      self.stop

      @zookeeper_observer.run

      @configuration.ring_size.times do |shard_number|
        shard_conf = ShardConfig.new(shard_number, configuration)
        @shards[shard_number] = Shard.new(shard_conf)
      end

      @shards.each do |shard_no, shard|
        @process_manager.start_shard(shard)
      end

      @process_manager.run
    end

    def stop
      @process_manager.halt
      @zookeeper_observer.halt

      @shards.each do |shard_no, shard|
        @process_manager.stop_shard(shard)
      end

      @shards = {}
    end

    def shards_hash
      shards_hash = {}
      shards.each do |shard_no, shard|
        shards_hash[shard_no] = { :host => shard.host, :port => shard.port, :status => shard.status }
      end

      return { :count => configuration.ring_size, :shards => shards_hash }
    end

    class << self
      attr_accessor :instance
    end

  end

end
