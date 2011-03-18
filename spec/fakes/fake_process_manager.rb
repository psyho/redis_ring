class FakeProcessManager

  def started_shards
    @started_shards ||= []
  end

  def start_shard(shard)
    started_shards << shard
  end

  def stopped_shards
    @stopped_shards ||= []
  end

  def stop_shard(shard)
    stopped_shards << shard
  end

end
