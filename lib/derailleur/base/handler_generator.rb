
require 'derailleur/core/handler'
require 'derailleur/base/context'

module Derailleur
  module HandlerGenerator
    # Creates a new subclass of Derailleur::Handler that will create a
    # Derailleur::Context which in turn will evaluate the block.
    # The dummy_params parameter is not used, but we need it because
    # it is the interface for Derailleur.Grease (in case you want to use
    # a custom HandlerGenerator)
    def self.for(dummy_params={}, &blk)
      handler = Class.new(Derailleur::Handler) 
      handler.send(:define_method, :to_rack_output) do
        context = Context.new(env, ctx, &blk)
        context.evaluate!
        context.result
      end
      handler
    end
  end
end
