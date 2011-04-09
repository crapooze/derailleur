
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/application'

describe Application, "in weird cases encountered in real life" do
  before :each do
    @weird_paths = ['peer/foo', 'peer/_bar', 'peer/__baz']

    @app = Module.new do
      extend Application
    end

    @weird_paths.each do |path|
      @app.build_route(path)
    end
  end

  it "should have a default root node type" do
    @weird_paths.each do |path|
      @app.get_route(path).should_not be_nil
      @app.get_route(File.join('/',path)).should_not be_nil
    end
  end
end

