module RedisRing

  class ShardConfig

    attr_reader :shard_number, :configuration

    def initialize(shard_number, configuration)
      @shard_number = shard_number
      @configuration = configuration
    end

    def render
      template = ERB.new(File.read(configuration.redis_config_template_path))
      return template.result(binding)
    end

    def save
      FileUtils.mkdir_p(configuration.base_directory)

      ['configs', 'logs', 'vm_files', 'db_files', working_directory].each do |dir_name|
        FileUtils.mkdir_p(File.join(configuration.base_directory, dir_name))
      end

      File.write(config_file_name, render)
    end

    def config_file_name
      File.join(configuration.base_directory, 'configs', "shard-#{shard_number}.conf")
    end

    def port
      configuration.base_port + shard_number + 1
    end

    def log_file
      file('logs', "shard-#{shard_number}.log")
    end

    def working_directory
      "#{configuration.base_directory}/work/shard-#{shard_number}"
    end

    def vm_swap_file
      file('vm_files', "shard-#{shard_number}.swap")
    end

    def vm_max_memory
      configuration.total_max_memory / configuration.ring_size
    end

    def vm_pages
      configuration.total_vm_size / configuration.vm_page_size / configuration.ring_size
    end

    def vm_page_size
      configuration.vm_page_size
    end

    def db_file_name
      file('db_files', "shard-#{shard_number}.rdb")
    end

    def aof_file_name
      file('db_files', "shard-#{shard_number}.aof")
    end

    def password
      configuration.password
    end

    def common_config_path
      "shared_config.conf"
    end

    protected

    def file(*parts)
      File.join('..', '..', *parts)
    end

  end

end
