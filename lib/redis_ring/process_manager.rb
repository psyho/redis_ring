module RedisRing

  class ShardAlreadyStarted < StandardError; end

  class ProcessManager

    include RedisRing::BackgroundThread

    def initialize
      @shards = {}
    end

    def do_work
      monitor_processes
      sleep(1)
    end

    def after_halt
      shards.each do |shard_no, shard|
        if shard.alive?
          puts "Stopping shard #{shard_no}"
          shard.stop
        end
      end
    end

    def start_shard(shard)
      if shards.key?(shard.shard_number)
        raise ShardAlreadyStarted.new("Shard: #{shard.shard_number} already started!")
      end

      shards[shard.shard_number] = shard
    end

    def stop_shard(shard)
      shards.delete(shard.shard_number)
      shard.stop
    end

    protected

    attr_reader :shards

    def monitor_processes
      shards.each do |shard_no, shard|
        unless shard.alive?
          puts "Restarting shard #{shard_no}"
          shard.start
        end
      end
    end

  end

end
