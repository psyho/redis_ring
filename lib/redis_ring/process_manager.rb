module RedisRing

  class ShardAlreadyStarted < StandardError; end

  class ProcessManager

    include RedisRing::BackgroundThread

    def initialize
      @shards = {}
      @shards_to_stop = []
      @mutex = Mutex.new
    end

    def do_work
      monitor_processes
      sleep(0.5)
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
      @mutex.synchronize do
        if shards.key?(shard.shard_number)
          raise ShardAlreadyStarted.new("Shard: #{shard.shard_number} already started!")
        end

        shards[shard.shard_number] = shard
      end
    end

    def stop_shard(shard)
      @mutex.synchronize do
        shards.delete(shard.shard_number)
        shards_to_stop << shard
      end
    end

    protected

    attr_reader :shards, :shards_to_stop

    def monitor_processes
      @mutex.synchronize do
        shards_to_stop.each do |shard|
          puts "Stopping shard #{shard.shard_number}"
          shard.stop
        end
        @shards_to_stop = []

        shards.each do |shard_no, shard|
          unless shard.alive?
            puts "Restarting shard #{shard_no}"
            shard.start
          end
        end
      end
    end

  end

end
