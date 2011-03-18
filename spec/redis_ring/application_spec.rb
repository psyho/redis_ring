require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Application do

  describe "integration (with just one node)" do
    it "should assign all of the shards to that node" do
      integration_test = File.expand_path("../../integration_test.rb", __FILE__)
      system("ruby #{integration_test}").should be_true
    end
  end

end
