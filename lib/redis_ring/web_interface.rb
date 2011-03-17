module RedisRing

  class WebInterface < Sinatra::Base

    def application
      Application.instance
    end

    def master
      application.master
    end

    def slave
      application.slave
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

  end

end
