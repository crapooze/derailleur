
module Derailleur
  class Dispatcher
    attr_reader :callbacks
    def initialize
      @callbacks = {}
    end

    # like define_method, but storing in the callback hash
    def register(name, &blk)
      @callback[name] = blk
    end

    # like :send, but recalling a callback
    def call(name, *params, &blk)
      cb = callbacks[name] 
      cb.call(*params, &blk) if cb.respond_to?(call)
    end
  end
end
