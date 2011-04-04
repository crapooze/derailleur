
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/rack/dispatcher'

describe HTTPDispatcher do
  it "should be created without handlers" do
    d = HTTPDispatcher.new
    d.no_handler?.should be_true
  end

  it "should record the handlers" do
    d = HTTPDispatcher.new
    HTTPDispatcher::HTTP_METHODS.each do |sym|
      d.send("#{sym}=", :foo)
      d.send(sym).should eql(:foo)
    end
  end

  it "should provide an array of paired handlers" do
    d = HTTPDispatcher.new
    d.handlers.should be_a(Array)
    d.handlers.map{|pair| pair.first}.should eql(Derailleur::HTTP_METHODS)
  end

  it "should give the default handler when needed" do
    d = HTTPDispatcher.new
    d.set_handler(:default, :foo)
    d.get_handler(:default).should eql(:foo)
  end

  it "should remember that handlers are set" do
    d = HTTPDispatcher.new
    d.set_handler(:GET, :foo)
    d.has_handler?(:GET).should be_true
  end
end
