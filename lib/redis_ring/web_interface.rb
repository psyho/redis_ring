module RedisRing

  class WebInterfaceRunner

    include  RedisRing::BackgroundThread

    attr_reader :master, :slave

    def initialize(port, master, slave)
      @port = port
      @master = master
      @slave = slave
    end

    def do_work
      handler = Rack::Handler.get("webrick")
      handler.run(WebInterface, :Port => @port, :master => @master, :slave => @slave) do |server|
        @server = server
        WebInterface.set :master, master
        WebInterface.set :slave, slave
        WebInterface.set :running, true
      end
    end

    def halt
      super
      @server.stop if @server
    end

  end

  class WebInterface < Sinatra::Base

    def master
      self.class.master
    end

    def slave
      self.class.slave
    end

    get "/" do
      "RedisRing is running"
    end

    post "/master/node_joined/:node_id" do
      master.node_joined(params[:node_id])
      "OK"
    end

    get "/slave/status" do
      content_type :json
      slave.status.to_json
    end

    post "/slave/join" do
      slave.join
      "OK"
    end

    post "/slave/start_shard/:shard_no" do
      slave.start_shard(params[:shard_no].to_i)
      "OK"
    end

    post "/slave/stop_shard/:shard_no" do
      slave.stop_shard(params[:shard_no].to_i)
      "OK"
    end

    class << self
      attr_accessor :master, :slave
    end

  end

end
