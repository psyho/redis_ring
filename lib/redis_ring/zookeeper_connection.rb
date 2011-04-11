module RedisRing

  class ZookeeperConnection

    attr_reader :current_node

    def initialize(cluster_name, host_name, base_port, zookeeper_address)
      @host_name = host_name
      @base_port = base_port
      @zookeeper_address = zookeeper_address
      @connected = false
      @base_path = "/#{cluster_name}"
      @mutex = Mutex.new
    end

    def nodes_changed?
      return true unless nodes_watcher
      return nodes_watcher.completed?
    end

    def nodes
      @nodes_watcher = Zookeeper::WatcherCallback.new
      resp = zookeeper.get_children(:path => base_path, :watcher => nodes_watcher, :watcher_context => base_path)
      return resp[:children].sort
    end

    def node_data(node)
      resp = zookeeper.get(:path => "#{base_path}/#{node}")
      data = resp[:data]
      return data ? JSON.parse(data) : nil
    end

    def update_status(status)
      status_path = "#{base_path}_cluster_status"
      if zookeeper.stat(:path => status_path)[:stat].exists
        zookeeper.set(:path => status_path, :data => status.to_json)
      else
        zookeeper.create(:path => status_path, :data => status.to_json)
      end
    end

    def connected?
      @connected
    end

    def connect
      @mutex.synchronize do
        break if connected?

        @zookeeper = Zookeeper.new(zookeeper_address)

        if @zookeeper.state != Zookeeper::ZOO_CONNECTED_STATE
          raise "Zookeeper not connected!"
        end

        resp = @zookeeper.create(:path => base_path)
        #raise "Could not create base path" unless resp[:rc] == Zookeeper::ZOK

        resp = @zookeeper.create(:path => "#{base_path}/node-", :ephemeral => true, :sequence => true, :data => current_node_data.to_json)
        #raise "Could not create node" unless resp[:rc] == Zookeeper::ZOK

        @current_node = resp[:path].gsub("#{base_path}/", '')

        @connected = true
      end
    end

    protected

    attr_reader :zookeeper, :base_path, :nodes_watcher, :zookeeper_address, :host_name, :base_port

    def current_node_data
      {:host => host_name, :port => base_port}
    end

  end

end
