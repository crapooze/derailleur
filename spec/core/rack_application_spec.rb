
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/application'

describe Application::RackApplication, "basics" do
  before :each do
    @app = Module.new do
      extend Application::RackApplication
    end
  end

  it "should have a default handler" do
    @app.default_handler.should_not be_nil
  end

  it "should have a default internal error handler" do
    @app.default_internal_error_handler.should_not be_nil
  end

  it "should have a default dispatcher" do
    @app.default_dispatcher.should_not be_nil
  end

  it "should store a default handler" do
    @app.default_handler = :foo
    @app.default_handler.should eql(:foo)
  end

  it "should store a default internal error handler" do
    @app.default_internal_error_handler = :foo
    @app.default_internal_error_handler.should eql(:foo)
  end

  it "should store a default dispatcher" do
    @app.default_dispatcher = :foo
    @app.default_dispatcher.should eql(:foo)
  end
end

describe Application::RackApplication, "path manipulations and registration" do
  before :each do
    @app = Module.new do
      extend Application::RackApplication
    end
  end

  it "should disallow registering '*'" do
    lambda{@app.register_route('*') }.should raise_error(ArgumentError)
  end

  it "should raise error when registering twice the same route" do
    @app.register_route('/foo/bar', :default, :foo) 
    lambda do
      @app.register_route('/foo/bar', :default, :bar) 
    end.should raise_error(RouteObjectAlreadyPresent)
  end

  it "should not raise error when registering twice the same route, with overwriting" do
    @app.register_route('/foo/bar', :default, :foo) 
    lambda do
      @app.register_route('/foo/bar', :default, :bar, :overwrite => true) 
    end.should_not raise_error(RouteObjectAlreadyPresent)
  end

  it "should return the last node" do
    @app.register_route('/foo/bar').name.should eql('bar')
  end

  it "should create a dispatcher" do
    d = @app.register_route('/foo/bar', :GET).content
    d.should_not be_nil
  end

  it "should set the dispatcher's content" do
    d = @app.register_route('/foo/bar', :GET, :foo).content
    d.get_handler(:GET).should eql(:foo)
  end

  it "should set the dispatcher's content as block" do
    n = @app.register_route('/foo/bar', :GET) do
      foo
    end
    n.content.get_handler(:GET).should be_a(Proc)
  end

  it "should give precedence to object handler" do
    n = @app.register_route('/foo/bar', :GET, :foo) do
      foo
    end
    n.content.get_handler(:GET).should equal(:foo)
  end

  it "should use only one dispatcher for the same node" do
    d1 = @app.register_route('/foo/bar', :GET).content
    d2 = @app.register_route('/foo/bar', :POST).content
    d1.should equal(d2)
  end

  it "should internally work on the routes, adding them one by one" do
    #a bit unreadable and too much tied to implementation
    m = mock('consecutive routes')
    d = mock('dispatcher')
    @app.default_root_node_type = m
    @app.default_dispatcher = d
    m.should_receive(:new).and_return(m)
    m.should_receive(:<<).with('').and_return(m)
    m.should_receive(:<<).with('foo').and_return(m)
    m.should_receive(:<<).with('bar').and_return(m)
    m.should_receive(:content).and_return(nil)
    d.should_receive(:new).and_return(d)
    m.should_receive(:content=).with(d).and_return(d)
    m.should_receive(:content).and_return(d)
    d.should_receive(:has_handler?).with(:foo).and_return(false)
    m.should_receive(:content).and_return(d)
    d.should_receive(:set_handler).with(:foo, :bar).and_return(d)
    @app.register_route('/foo/bar', :foo, :bar) 
  end
end

describe Application::RackApplication, "route getting" do
  before :each do
    @app = Module.new do
      extend Application::RackApplication
    end
  end

  it "should say there's no such route" do
    lambda {@app.get_route('/foo/bar')}.should raise_error(NoSuchRoute)
  end

  it "should find the correct route" do
    n0 = @app.register_route('/foo/bar/baz')
    n1 = @app.get_route('/foo/bar/baz')
    n1.should equal(n0)
  end

  it "should absorb routes correctly" do
    n0 = @app.register_route('/foo/*')
    n1 = @app.get_route('/foo/bar/baz')
    n1.should equal(n0)
  end

  it "should yield consecutively" do
    n0 = @app.register_route('/foo')
    n1 = @app.register_route('/foo/bar')
    ary = []
    @app.get_route('/foo/bar') do |n,p|
      ary << [n,p]
    end
    ary.should have(3).items
    ary.transpose[1].should eql(['', 'foo', 'bar'])
    ary.transpose[0].should eql([@app.routes.children.first, n0, n1])
  end
end

describe Application::RackApplication, "route unregistration" do
  before :each do
    @app = Module.new do
      extend Application::RackApplication
    end
  end

  it "should unregister path correctly" do
    @app.register_route('/foo/bar')
    @app.unregister_route('/foo/bar')
    lambda {@app.get_route('/foo/bar')}.should raise_error(NoSuchRoute)
  end

  it "should prune routes" do
    @app.register_route('/foo/bar')
    @app.unregister_route('/foo/bar')
    @app.routes.children.should be_empty
  end

  it "should leave intermediate nodes accessibles" do
    @app.register_route('/foo/bar/baz')
    @app.unregister_route('/foo/bar')
    lambda {@app.get_route('/foo/bar/baz')}.should_not raise_error(NoSuchRoute)
  end

  it "should only remove a handler from the dispatcher" do
    @app.register_route('/foo/bar', :GET, :foo)
    @app.register_route('/foo/bar', :POST, :foo)
    @app.unregister_route('/foo/bar', :GET)
    d = @app.get_route('/foo/bar').content
    d.has_handler?(:GET).should be_false
    d.has_handler?(:POST).should be_true
  end
end

describe Application::RackApplication, "route unregistration" do
  before :each do
    @app1 = Module.new do
      extend Application::RackApplication
    end
    @app2 = Module.new do
      extend Application::RackApplication
    end
  end

  it "should place the whole branch in the second application" do
    @app1.register_route('/foo/bar/baz', :GET, :foo)
    @app1.split_to!('/foo/bar', @app2)
    
    lambda{@app1.get_route('/foo/bar/baz')}.should raise_error
    lambda{@app2.get_route('/foo/bar/baz')}.should_not raise_error
    node = @app2.get_route('/foo/bar/baz')
    node.content.should_not be_nil
    node.content.has_handler?(:GET).should be_true
  end

  it "should not raise error when the split is risky" do
    @app1.register_route('/foo/bar/baz', :GET, :foo)
    @app2.register_route('/foo/bar/baz', :GET, :foo)
    lambda { @app1.split_to!('/foo/bar', @app2) }.should_not raise_error(ArgumentError)
  end
end
