require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Configuration do
  describe "defaults" do
    before(:each) do
      @config = RedisRing::Configuration.new
    end

    it "should have default port" do
      @config.base_port.should_not be_nil
      @config.base_port.should be_an_instance_of(Fixnum)
    end

    it "should have default host" do
      @config.host_name.should_not be_nil
      @config.host_name.should =~ /\d+\.\d+\.\d+.\d+/
    end

    it "should have default ring_size" do
      @config.ring_size.should_not be_nil
      @config.base_port.should be_an_instance_of(Fixnum)
      @config.base_port.should > 0
    end

    it "should have default redis_path" do
      @config.redis_path.should_not be_nil
      File.exist?(@config.redis_path).should be_true
    end

    it "should have default redis_config_template_path" do
      @config.redis_config_template_path.should_not be_nil
      File.exist?(@config.redis_config_template_path).should be_true
    end
  end
end
