module RedisRing

  class ShardAlreadyStarted < StandardError; end

  class ProcessManager

    def initialize
      @shards = {}
    end

    def run
      @continue_running = true
      Thread.new do
        monitor_processes_loop
      end
    end

    def halt
      @continue_running = false
    end

    def start_shard(shard)
      if shards.key?(shard.shard_number)
        raise ShardAlreadyStarted.new("Shard: #{shard.shard_number} already started!")
      end

      shards[shard.shard_number] = shard

      shard.start
    end

    def stop_shard(shard)
      shards.delete(shard.shard_number)
      shard.stop
    end

    protected

    attr_reader :shards

    def monitor_processes_loop
      while(@continue_running) do
        shards.each do |shard_no, shard|
          unless shard.alive?
            puts "Restarting shard #{shard_no}"
            shard.start
          end
        end
        sleep(1)
      end
    end

  end

end
