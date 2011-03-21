require File.expand_path("../../spec_helper", __FILE__)

describe RedisRing::Application do

  before(:each) do
    @conf = RedisRing::Configuration.from_yml_file(File.expand_path("../../test.conf", __FILE__))
    @app = RedisRing::Application.new(@conf)
  end

  it "should run shards" do
    @app.start
    sleep(1)

    @app.slave.join
    sleep(3)

    @app.slave.running_shards.keys.sort.should == [0, 1, 2, 3]
  end

  after(:each) do
    @app.stop
    @app.wait
  end

end
