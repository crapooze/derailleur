
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/application'

describe Application, "basics" do

  before :each do
    @app = Module.new do
      extend Application
    end
  end

  it "should have a default root node type" do
    @app.default_root_node_type.should_not be_nil
  end

  it "should store a default root node type" do
    @app.default_root_node_type = :foo
    @app.default_root_node_type.should eql(:foo)
  end

  it "should get the node type from the root node type" do
    m = mock('root node')
    @app.default_root_node_type = m
    m.should_receive(:node_type)
    @app.default_node_type
  end

  it "should build the routes when needed" do
    m = mock('root node')
    @app.default_root_node_type = m
    m.should_receive(:new).and_return(:object)
    r1 = @app.routes
    r1.should equal(:object)
    r2 = @app.routes
    r1.should equal(r2)
  end
end

describe Application, "path manipulations and registration" do
  before :each do
    @app = Module.new do
      extend Application
    end
  end

  it "should normalize paths" do
    @app.normalize('/foo/bar').should eql('/foo/bar')
    @app.normalize('foo/bar').should eql('/foo/bar')
  end

  it "should chunk paths and add the root" do
    @app.chunk_path('foo/bar/baz').should eql(['', 'foo', 'bar', 'baz'])
    @app.chunk_path('/foo/bar/baz').should eql(['', 'foo', 'bar', 'baz'])
  end

  it "should build path nodes correctly, including the root node" do
    @app.build_route('/foo') 
    routes = @app.routes
    routes.children.should have(1).item
    root = routes.children.first
    root.name.should be_empty
    root.children.should have(1).item
    root.children.first.name.should eql('foo')
  end

  it "should not make unecessary duplicates entries" do
    @app.build_route('/foo/bar') 
    @app.build_route('/foo/baz') 
    @app.build_route('/foo/:lol') 
    routes = @app.routes
    routes.children.should have(1).item
    root = routes.children.first
    root.name.should be_empty
    root.children.should have(1).item
    foo = root.children.first
    foo.children.should have(3).items
  end
end

describe Application, "path retrieval" do
  before :each do
    @app = Module.new do
      extend Application
    end
    @app.build_route('/foo/bar')
  end

  it "should find the route" do
    @app.get_route('/foo').should_not be_nil
    @app.get_route('/foo/bar').should_not be_nil
  end

  it "should find the route silently" do
    @app.get_route_silent('/foo').should_not be_nil
    @app.get_route_silent('/foo/bar').should_not be_nil
  end

  it "should complain about not finding the route" do
    lambda { @app.get_route('/bar')}.should raise_error
  end

  it "should not complain about not finding the route silently" do
    lambda { @app.get_route_silent('/bar')}.should_not raise_error
  end
end
