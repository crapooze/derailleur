
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/rack/handler'

describe RackHandler, 'A top class for rack handlers' do
  it "should have the default 200 status" do
    h = RackHandler.new
    h.status.should equal(200)
  end

  it "should have the default empty headers" do
    h = RackHandler.new
    h.headers.should eql({})
  end

  it "should have the default empty page" do
    h = RackHandler.new
    h.page.should eql('')
  end

  it "should build a Rack output" do
    h = RackHandler.new()
    h.status = :foo
    h.headers = :bar
    h.page = :baz
    h.to_rack_output.should eql([:foo, :bar, :baz])
  end
end

describe DefaultRackHandler, 'A one size-fits almost all handler for Rack' do
  before :each do 
    @mock = mock('object')
  end

  it "should call a proc with env and ctx" do
    h = DefaultRackHandler.new(@mock, :foo, :bar)
    @mock.should_receive(:call).with(:foo, :bar)
    h.do_proc_output
  end

  it "should forward method call after copying env and ctx" do
    h = DefaultRackHandler.new(@mock, :foo, :bar)
    @mock.should_receive(:env=).with(:foo)
    @mock.should_receive(:ctx=).with(:bar)
    @mock.should_receive(:to_rack_output)
    h.do_forward_output
  end

  it "should select the forwarding output" do
    h = DefaultRackHandler.new(@mock, :foo, :bar)
    def @mock.to_rack_output
    end
    @mock.should_receive(:env=).with(:foo)
    @mock.should_receive(:ctx=).with(:bar)
    @mock.should_receive(:to_rack_output)
    h.to_rack_output
  end

  it "should select the non forwarded output" do
    h = DefaultRackHandler.new(Object.new, :foo, :bar)
    def h.do_non_forward_output
      raise StandardError, "just a test"
    end
    lambda { h.to_rack_output }.should raise_error(StandardError, 'just a test')
  end

  it "should instanciate an object and get its rack output" do
    h = DefaultRackHandler.new(@mock, :foo, :bar)
    mock_instance = mock('instanced')
    @mock.should_receive(:new).with(nil, :foo, :bar).and_return(mock_instance)
    mock_instance.should_receive(:to_rack_output)
    h.do_handler_instantiation_output
  end

  it "should raise an error when no handling scheme is known" do
    h = DefaultRackHandler.new(Object.new, :foo, :bar)
    lambda { h.do_non_forward_output }.should raise_error(InvalidHandler)
  end

  it "should raise an error when no instanciation and handling scheme is known" do
    h = DefaultRackHandler.new(Class.new, :foo, :bar)
    lambda { h.do_non_forward_output }.should raise_error(InvalidHandler)
  end

  it "should instanciates other RackHandler classes" do
    h = DefaultRackHandler.new(Class.new(RackHandler), :foo, :bar)
    def h.do_handler_instantiation_output
      raise StandardError, "just a test"
    end
    lambda { h.do_non_forward_output }.should raise_error(StandardError, 'just a test')
  end

  it "should call the proc output" do
    blk = Proc.new do 
    end
    h = DefaultRackHandler.new(blk, :foo, :bar)
    def h.do_proc_output
      raise StandardError, "just a test"
    end
    lambda { h.do_non_forward_output }.should raise_error(StandardError, 'just a test')
  end
end

describe RackApplicationHandler, 'A Rack app handler' do
  it "should call the Rack app" do
    m = mock('rack app')
    h = RackApplicationHandler.new(m, :foo, :bar)
    m.should_receive(:call).with(:foo)
    h.to_rack_output
  end
end

describe InternalErrorHandler, 'An handler called when it crashes' do
  it "should have a 500 status" do
    h = InternalErrorHandler.new(nil, nil, nil)
    h.status.should equal(500)
  end

  it "should have text/plain headers" do
    h = InternalErrorHandler.new(nil, nil, nil)
    h.headers.should eql({'Content-Type' => 'text/plain'})
  end

  it "should also have :err aliased to :object" do
    h = InternalErrorHandler.new(:foo, nil, nil)
    h.err.should equal(:foo)
  end

  it "should copy the error status" do
    o = Object.new
    def o.http_status
      :bar
    end
    h = InternalErrorHandler.new(o, nil, nil)
    h.status.should equal(:bar)
  end

  it "should build a page with a lot of content" do
    m = mock('error')
    h = InternalErrorHandler.new(m, nil, nil)
    m.should_receive(:class).and_return(Class)
    m.should_receive(:message).and_return('foo')
    m.should_receive(:backtrace).and_return('bar')
    h.page.should eql("Class\nfoo\nbar")
  end
end
