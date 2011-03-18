require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::SlaveRPC do

  before(:each) do
    @http_client = FakeHttpClient.new
    @host = "example.com"
    @port = 666
    @rpc = RedisRing::SlaveRPC.new(@http_client).connection(@host, @port)
  end

  describe :join do
    it "should post to joined url" do
      @rpc.join

      @http_client.sent_post?("http://example.com:666/slave/join").should be_true
    end
  end

  describe :status do
    it "should get and parse status" do
      @http_client.set_response("http://example.com:666/slave/status", {"parsed" => "yes"}.to_json)
      result = @rpc.status

      @http_client.sent_get?("http://example.com:666/slave/status").should be_true
      result.should == {"parsed" => "yes"}
    end
  end

  describe :start_shard do
    it "should get and parse status" do
      @rpc.start_shard(1)

      @http_client.sent_post?("http://example.com:666/slave/start_shard/1").should be_true
    end
  end

  describe :stop_shard do
    it "should get and parse status" do
      @rpc.stop_shard(1)

      @http_client.sent_post?("http://example.com:666/slave/stop_shard/1").should be_true
    end
  end

end
