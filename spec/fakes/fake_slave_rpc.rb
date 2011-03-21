class FakeSlaveRPC

  def connection(host, port)
    @connections ||= {}
    @connections["#{host}:#{port}"] ||= Connection.new
  end

  class Connection

    def status=(val)
      @status = val
    end

    def status
      @status ||= {"joined" => false, "running_shards" => [], "available_shards" => {}}
    end

    def started_shards
      @started_shards ||= []
    end

    def start_shard(shard_number)
      started_shards << shard_number
    end

    def stopped_shards
      @stopped_shards ||= []
    end

    def stop_shard(shard_number)
      stopped_shards << shard_number
    end

  end

end
