
require 'derailleur/core/application'
require 'derailleur/rack/handler'
require 'derailleur/rack/dispatcher'
require 'derailleur/rack/errors'

module Derailleur
  module RackApplication
    include Application

    attr_writer :default_internal_error_handler
    attr_writer :default_handler
    attr_writer :default_dispatcher

    # The default HTTP method dispatcher ( Derailleur::HTTPDispatcher )
    # See Derailleur::HTTPDispatcher if you want a personal one
    def default_dispatcher
      @default_dispatcher ||= HTTPDispatcher
    end

    # The default error handler ( Derailleur::InternalErrorHandler )
    def default_internal_error_handler
      @default_internal_error_handler ||= InternalErrorHandler
    end

    # The default handler ( Derailleur::DefaultRackHandler )
    # See Derailleur::Handler to understand how to build your own
    def default_handler
      @default_handler ||= DefaultRackHandler
    end

    # Method implemented to comply to the Rack specification.  see
    # http://rack.rubyforge.org/doc/files/SPEC.html to understand what to
    # return.
    #
    # If everything goes right, an instance of default_handler will serve
    # the request.
    #
    # The routing handler will be created with three params
    # - the application handler contained in the dispatcher
    # - the Rack env
    # - a context hash with three keys:
    #   * 'derailleur' at self, i.e., a reference to the application
    #   * 'derailleur.params' with the parameters/spalt in the path
    #   * 'derailleur.node' the node responsible for handling this path
    # 
    # If there is any exception during this, it will be catched and the 
    # default_internal_error_handler will be called.
    def call(env)
      begin
        path = env['PATH_INFO'].sub(/\.\w+$/,'') #ignores the extension if any
        ctx = {}
        route, params = get_route_with_params(path)
        ctx['derailleur.node'] = route
        ctx['derailleur.params'] = params
        ctx['derailleur'] = self
        dispatcher = route.content
        raise NoSuchRoute, "no dispatcher for #{path}" if dispatcher.nil?
        handler = dispatcher.send(env['REQUEST_METHOD'])
        raise NoSuchRoute, "no handler for valid path: #{path}" if handler.nil?
        default_handler.new(handler, env, ctx).to_rack_output
      rescue Exception => err
        default_internal_error_handler.new(err, env, ctx).to_rack_output
      end
    end

    # Registers an handler for a given path.
    # The path will be interpreted as an absolute path prefixed by '/' .
    #
    # Usually you will not use this method but a method from the 
    # higher level code (with the name of the HTTP method: e.g. get post put)
    #
    # The method argument is the method name for the dispatcher, as a symbol 
    # (e.g. :GET)
    #
    # (handler || blk) is the handler set. i.e., if there's both a handler
    # and a block, the block will be ignored.
    #
    # Params is hash of parameters, currently, the only key 
    # looked at is :overwrite to overwrite an handler for an 
    # existing path/method pair.
    #
    # Internally, the path will be created node by node when nodes for this
    # path are missing.
    def register_route(path, method=:default, handler=nil, params={}, &blk)
      if path == '*'
        raise ArgumentError.new("Cannot register on #{path} because of ambiguity, in Derailleur, '*' translated'/*' would not catch the path '/' like '/foo/*' doesn't catch '/foo'")
      end
      handler = handler || blk
      node = build_route(path)
      node.content ||= default_dispatcher.new
      if (params[:overwrite]) or (not node.content.has_handler?(method))
        node.content.set_handler(method, handler)
      else
        raise RouteObjectAlreadyPresent, "could not overwrite #{method} handler at path #{path}"
      end
      node
    end

    # Removes an handler for a path/method pair.
    # The path will be interpreted as an absolute path prefixed with '/'
    def unregister_route(path, method=:default)
      node = get_route(normalize(path))
      if node.children.empty?
        if node.content.no_handler?
          node.prune! 
        else
          node.content.set_handler(method, nil)
        end
      else
        node.hand_off_to! default_node_type.new(node.name)
      end
    end

  end
end
