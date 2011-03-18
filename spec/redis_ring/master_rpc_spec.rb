require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::MasterRPC do

  before(:each) do
    @http_client = FakeHttpClient.new
    @host = "example.com"
    @port = 666
    @rpc = RedisRing::MasterRPC.new(@http_client).connection(@host, @port)
  end

  describe :node_joined do
    it "should post to node joined url" do
      @rpc.node_loaded("some_node_id")

      @http_client.sent_post?("http://example.com:666/master/node_joined/some_node_id").should be_true
    end
  end

end
