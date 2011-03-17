module RedisRing

  class Application

    attr_reader :shards, :configuration, :process_manager, :zookeeper_observer, :master, :slave, :zookeeper_connection, :master_rpc, :http_client, :node_provider, :slave_rpc

    def initialize(config)
      @configuration = config
      @process_manager = ProcessManager.new
      @http_client = HttpClient.new
      @master_rpc = MasterRPC.new(http_client)
      @slave_rpc = SlaveRPC.new(http_client)
      @node_provider = NodeProvider.new(slave_rpc)
      @zookeeper_connection = ZookeeperConnection.new(config.host_name,
                                                      config.base_port,
                                                      config.zookeeper_address)
      @master = Master.new(zookeeper_connection, config.ring_size, node_provider)
      @slave = Slave.new(configuration, master_rpc, process_manager)
      @zookeeper_observer = ZookeeperObserver.new(zookeeper_connection, master, slave)
    end

    def start
      self.stop

      web_thread = Thread.new do
        WebInterface.run!(:port => configuration.base_port)
        Application.instance.stop
      end

      @zookeeper_connection.connect
      @slave.node_id = @zookeeper_connection.current_node

      @zookeeper_observer.run
      @process_manager.run

      web_thread.join
    end

    def stop
      @process_manager.halt
      @zookeeper_observer.halt
    end

    class << self
      attr_accessor :instance
    end

  end

end
