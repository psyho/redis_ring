module RedisRing

  class ZookeeperObserver

    include RedisRing::BackgroundThread

    attr_reader :master, :slave, :zookeeper_connection

    def initialize(zookeeper_connection, master, slave)
      @zookeeper_connection = zookeeper_connection
      @master = master
      @slave = slave
      @current_master = nil
    end

    def do_work
      on_node_list_changed(zookeeper_connection.nodes) if zookeeper_connection.nodes_changed?
      sleep(0.1)
    end

    protected

    def on_node_list_changed(new_nodes)
      current_master = new_nodes.first

      unless @current_master == current_master
        @current_master = current_master

        if current_master == zookeeper_connection.current_node
          master.became_master
        else
          master.no_longer_is_master
        end

        current_master_data = zookeeper_connection.node_data(current_master)
        slave.current_master_host = current_master_data["host"]
        slave.current_master_port = current_master_data["port"]

        puts "NEW MASTER IS: #{slave.current_master_host}:#{slave.current_master_port}"
      end

      master.nodes_changed(new_nodes)
    end

  end

end
