module RedisRing

  class ConfigurationError < StandardError; end

  class Configuration

    attr_reader :host_name, :base_port, :ring_size, :redis_path, :redis_config_template_path

    def initialize(yml_string = '')
      @host_name ||=  guess_host_name
      @base_port ||= 6400
      @ring_size ||= 128
      @redis_path ||= locate_redis
      @redis_config_template_path ||= default_redis_config_template_path
    end

    def self.load(file_name)
    end

    protected

    def guess_host_name
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        return s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end

    def locate_redis
      path = %x[which redis-server].strip
      if path.empty?
        raise ConfigurationError.new("Could not find redis-server in path!")
      end
      return path
    end

    def default_redis_config_template_path
      File.expand_path('../../../config/redis.conf.erb', __FILE__)
    end

  end

end
