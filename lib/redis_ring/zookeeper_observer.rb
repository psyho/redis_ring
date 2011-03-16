module RedisRing

  class ZookeeperObserver

    attr_reader :configuration, :master

    def initialize(configuration, master)
      @configuration = configuration
      @master = master
      @connected = false
      @base_path = "/nodes"
    end

    def run
      connect

      @continue_running = true

      Thread.new do
        while(@continue_running) do
          wait_for_nodes_to_change
        end
      end
    end

    def halt
      @continue_running = false
    end

    protected

    attr_reader :zookeeper, :current_node, :base_path

    def connected?
      @connected
    end

    def connect
      return if connected?
      @zookeeper = Zookeeper.new(configuration.zookeeper_address)

      if @zookeeper.state != Zookeeper::ZOO_CONNECTED_STATE
        raise "Zookeeper not connected!"
      end

      resp = @zookeeper.create(:path => base_path)
      #raise "Could not create base path" unless resp[:rc] == Zookeeper::ZOK

      resp = @zookeeper.create(:path => "#{@base_path}/node-", :ephemeral => true, :sequence => true, :data => node_data.to_json)
      #raise "Could not create node" unless resp[:rc] == Zookeeper::ZOK

      @current_node = resp[:path]

      @connected = true
    end

    def node_data
      {:host => configuration.host_name, :port => configuration.base_port}
    end

    def on_node_list_changed(new_nodes)
      current_master = new_nodes.first
      if current_master == current_node
        master.became_master
      else
        master.no_longer_is_master
      end
      master.nodes_changed(new_nodes)
    end

    def wait_for_nodes_to_change
      wcb = Zookeeper::WatcherCallback.new
      resp = zookeeper.get_children(:path => base_path, :watcher => wcb, :watcher_context => base_path)
      children = resp[:children].map{|name| "#{base_path}/#{name}"}

      on_node_list_changed(children.sort)

      while @continue_running && !wcb.completed?
        sleep(0.1)
      end
    end

  end

end
