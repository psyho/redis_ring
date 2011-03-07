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
      shard_config.save
      @pid = fork_redis_server
      @status = :started
    end

    def stop
      send_kill_signal
      @status = :stopped
    end

    protected

    def alive?
      @pid && File.exist?("/proc/#{@pid}")
    end

    def fork_redis_server
      spawn(shard_config.redis_path, shard_config.config_file_name)
    end

    def send_kill_signal
      system("kill -QUIT #{pid}")
    end

  end

end
