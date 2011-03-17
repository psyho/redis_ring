module RedisRing
  class SlaveRPC

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

      def join
        http_client.post(host, port, "/slave/join")
      end

      def status
        JSON.parse(http_client.get(host, port, "/slave/status"))
      end

      def start_shard(shard_no)
        http_client.post(host, port, "/slave/start_shard/#{shard_no}")
      end

      def stop_shard(shard_no)
        http_client.post(host, port, "/slave/stop_shard/#{shard_no}")
      end

    end
  end
end
