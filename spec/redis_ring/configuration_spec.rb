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

    it "should have default total_vm_size" do
      @config.total_vm_size.should_not be_nil
      @config.total_vm_size.should > 0
    end

    it "should have default base_directory" do
      @config.base_directory.should_not be_nil
    end

    it "should have no password by default" do
      @config.password.should be_nil
    end

    it "should have default total_memory" do
      @config.total_max_memory.should_not be_nil
      @config.total_max_memory.should > 0
    end

    it "should have default vm_page_size" do
      @config.vm_page_size.should_not be_nil
      @config.vm_page_size.should > 0
    end
  end

  it "should rise RedisNotFound exception if redis-server not found" do
    lambda {
      RedisRing::Configuration.new(:redis_path => '/this/does/not/exist')
    }.should raise_exception(RedisRing::RedisNotFound)
  end

  it "should rise UnknownConfigurationParameter exception if an unknown configuration parameter is given" do
    lambda {
      RedisRing::Configuration.new(:unknown_parameter => 'some value')
    }.should raise_exception(RedisRing::UnknownConfigurationParameter)
  end

  it "should load yml config" do
    yml_string = <<-YML
    base_port: 666
    base_directory: /home/psyho/redis
    YML

    config = RedisRing::Configuration.from_yml(yml_string)

    config.base_port.should == 666
    config.base_directory.should == '/home/psyho/redis'
  end
end
