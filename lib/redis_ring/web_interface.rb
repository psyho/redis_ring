module RedisRing

  class WebInterface < Sinatra::Base

    get "/" do
      "RedisRing is running"
    end

    get "/shards" do
      content_type :json
      Application.instance.shards_hash.to_json
    end

  end

end
