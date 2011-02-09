
module Derailleur
  HTTP_METHODS = [:GET, :HEAD, :POST, :PUT, :DELETE, :default]
  Dispatcher = Struct.new(*HTTP_METHODS) do
    # returns the handler for an HTTP method, or, the default one
    def get_handler(method)
      send(method) || send(:default)
    end

    # returns true if a handler is set for the HTTP method in param
    # it is an alternative to get_handler which would return a true value
    # if there is a default handler
    def has_handler?(method)
      send(method) && true
    end

    # sets a handler for the HTTP method in param to val
    def set_handler(method, val)
      send("#{method}=", val)
    end

    # Returns an array of pairs of array with [HTTP-verbs, handler]
    # an extra item is the :default handler
    # NB: could also be a hash, but I'm fine with it
    def handlers
      HTTP_METHODS.map do |sym|
        [sym, send(sym)]
      end
    end

    # returns an array like handlers but restricted to the not nil values
    def handlers_set
      handlers.reject{|sym, handler| handler.nil?}
    end

    # Returns true if there is no handler set for this dispatcher
    def no_handler?
      handlers_set.empty?
    end
  end
end
