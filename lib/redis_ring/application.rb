module RedisRing

  class Application

    attr_reader :shards, :configuration

    def initialize(configuration)
      @configuration = configuration
      @shards = {}
    end

    def start
      self.stop

      @configuration.ring_size.times do |shard_number|
        shard_conf = ShardConfig.new(shard_number, configuration)
        @shards[shard_number] = Shard.new(shard_conf)
      end

      @shards.each do |shard_no, shard|
        shard.start
      end
    end

    def stop
      @shards.each do |shard_no, shard|
        shard.stop
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
