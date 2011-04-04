
module Derailleur
  class Handler
    attr_accessor :env, :ctx, :object
    def initialize(obj=nil, env=nil, ctx=nil)
      @env = env
      @ctx = ctx
      @object = obj
    end
  end
end
