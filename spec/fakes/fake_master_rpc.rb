class FakeMasterRPC

  def connection(host, port)
    @connections ||= {}
    @connections["#{host}:#{port}"] ||= Connection.new
  end

  class Connection

    def nodes_loaded
      @node_loaded ||= []
    end

    def node_loaded(node_id)
      nodes_loaded << node_id
    end

  end

end
