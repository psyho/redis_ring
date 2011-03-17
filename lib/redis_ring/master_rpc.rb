module RedisRing

  class MasterRPC

    attr_reader :http_client

    def initialize(http_client)
      @http_client = http_client
    end

    def connection(host, port)
      Connection.new(http_client, host, port)
    end

    class Connection

      attr_reader :http_client, :host, :port

      def initialize(http_client, host, port)
        @http_client = http_client
        @host = host
        @port = port
      end

      def node_loaded(node_id)
        http_client.post(host, port, "/master/node_joined/#{node_id}")
      end

    end

  end

end
