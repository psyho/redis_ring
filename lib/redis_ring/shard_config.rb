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
      FileUtils.mkdir_p(working_directory)

      ['configs', 'logs', 'vm_files', 'db_files'].each do |dir_name|
        FileUtils.mkdir_p(File.join(configuration.base_directory, dir_name))
      end

      FileUtils.touch(common_config_path) unless File.exist?(common_config_path)

      File.open(config_file_name, 'w') { |f| f.write(render) }
    end

    def config_file_name
      File.join(configuration.base_directory, 'configs', "shard-#{shard_number}.conf")
    end

    def host
      configuration.host_name
    end

    def port
      configuration.base_port + shard_number + 1
    end

    def redis_path
      configuration.redis_path
    end

    def log_file
      File.expand_path(file('logs', "shard-#{shard_number}.log"), working_directory)
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

    def db_mtime
      mtime(db_file_name)
    end

    def aof_mtime
      mtime(aof_file_name)
    end

    def password
      configuration.password
    end

    def common_config_path
      File.join(configuration.base_directory, "shared_config.conf")
    end

    protected

    def file(*parts)
      File.join('..', '..', *parts)
    end

    def mtime(relative_path)
      path = File.expand_path(relative_path, working_directory)
      return nil unless File.exist?(path)
      return File.mtime(path).to_i
    end

  end

end
