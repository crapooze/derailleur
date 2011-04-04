
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/handler'

describe Handler, 'A top class for all kinds of handlers' do
  it "should have nothing set" do
    h = Handler.new
    h.ctx.should be_nil
    h.env.should be_nil
    h.object.should be_nil
  end

  it "should be able to have an env, a ctx, and an object" do
    h = Handler.new(:foo, :bar, :baz)
    h.object.should equal(:foo)
    h.env.should equal(:bar)
    h.ctx.should equal(:baz)
  end
end
