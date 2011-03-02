module RedisRing

  class ConfigurationError < StandardError; end
  class RedisNotFound < ConfigurationError; end
  class UnknownConfigurationParameter < ConfigurationError; end

  class Configuration

    PARAMETERS = [:host_name, :base_port, :ring_size, :redis_path, :redis_config_template_path,
      :total_vm_size, :base_directory, :password, :total_max_memory, :vm_page_size]

    attr_reader *PARAMETERS

    def initialize(params = {})
      set_params(params)
      set_defaults
      validate!
    end

    def self.from_yml_file(file_name)
      return from_yml(File.read(file_name))
    end

    def self.from_yml(string)
      args = YAML::load(string)
      return new(args)
    end

    protected

    attr_writer *PARAMETERS

    def set_params(params)
      params.each do |param, value|
        if PARAMETERS.include?(param.to_sym)
          self.send("#{param}=", value)
        else
          raise UnknownConfigurationParameter.new("Unknown configuration parameter: #{param.inspect}")
        end
      end
    end

    def set_defaults
      self.host_name ||=  guess_host_name
      self.base_port ||= 6400
      self.ring_size ||= 32
      self.redis_path ||= locate_redis
      self.redis_config_template_path ||= default_redis_config_template_path
      self.total_vm_size ||= 8 * 1024 * 1024 * 1024 # 8GB
      self.base_directory ||= "/var/lib/redis"
      self.total_max_memory ||= 1024 * 1024 * 1024 # 1GB
      self.vm_page_size ||= 32
    end

    def validate!
      raise RedisNotFound.new("redis_path is invalid (not found)") unless File.file?(redis_path)
    end

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
      return %x[which redis-server].strip
    end

    def default_redis_config_template_path
      File.expand_path('../../../config/redis.conf.erb', __FILE__)
    end

  end

end
