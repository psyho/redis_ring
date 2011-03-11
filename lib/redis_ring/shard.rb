module RedisRing

  class Shard

    attr_reader :shard_config, :pid

    def initialize(shard_config)
      @shard_config = shard_config
      @status = :stopped
    end

    def shard_number
      shard_config.shard_number
    end

    def host
      shard_config.host
    end

    def port
      shard_config.port
    end

    def status
      if @status == :stopped
        return alive? ? :stopping : :stopped
      elsif @status == :started
        return alive? ? :running : :dead
      else
        raise RuntimeException.new("Unknown status: #{@status.inspect}")
      end
    end

    def start
      if @status == :started
        @task.start unless @task.running?
      else
        shard_config.save
        @task = fork_redis_server
        @status = :started
      end
    end

    def stop
      @task.stop
      @status = :stopped
    end

    def alive?
      @task && @task.running?
    end

    protected

    def fork_redis_server
      Daemons.call(:multiple => true) do
        exec(shard_config.redis_path, shard_config.config_file_name)
      end
    end

  end

end
