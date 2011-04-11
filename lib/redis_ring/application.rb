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
      @zookeeper_connection = ZookeeperConnection.new(config.cluster_name,
                                                      config.host_name,
                                                      config.base_port,
                                                      config.zookeeper_address)
      @master = Master.new(zookeeper_connection, config.ring_size, node_provider)
      @slave = Slave.new(configuration, master_rpc, process_manager)
      @zookeeper_observer = ZookeeperObserver.new(zookeeper_connection, master, slave)
      @web_interface_runner = WebInterfaceRunner.new(config.base_port, master, slave)
    end

    def start
      self.stop

      @web_thread = @web_interface_runner.run

      @zookeeper_connection.connect
      @slave.node_id = @zookeeper_connection.current_node

      @zookeeper_thread = @zookeeper_observer.run
      @pm_thread = @process_manager.run

      [:INT, :TERM, :QUIT].each do |sig|
        trap(sig) { self.stop }
      end
    end

    def wait
      @pm_thread.join if @pm_thread
      @zookeeper_thread.join if @zookeeper_thread
      @web_thread.join if @web_thread
    end

    def stop
      @process_manager.halt
      @zookeeper_observer.halt
      @web_interface_runner.halt
    end

  end

end
