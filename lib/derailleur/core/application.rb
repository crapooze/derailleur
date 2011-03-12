
require 'derailleur/core/errors'

module Derailleur
  autoload :InternalErrorHandler, 'derailleur/core/handler'
  autoload :DefaultRackHandler, 'derailleur/core/handler'
  autoload :ArrayTrie, 'derailleur/core/array_trie'
  autoload :Dispatcher, 'derailleur/core/dispatcher'

  # In Derailleur, an application is an object extending the Application
  # module.  It will have routes which hold handlers.  By default, we use
  # Derailleur's components, but you can easily modify your application to use
  # custom routes' node, HTTP methods dispatcher, and handlers.
  module Application

    attr_writer :default_handler, :default_root_node_type, :default_dispatcher,
      :default_internal_error_handler

    # The default error handler ( Derailleur::InternalErrorHandler )
    def default_internal_error_handler
      @default_internal_error_handler ||= InternalErrorHandler
    end

    # The default root node type ( Derailleur::ArrayTrie )
    # You could change it to ( Derailleur::HashTrie ) for better performance.
    # The rule of thumb is: benchmark your application with both and pick the 
    # best one.
    def default_root_node_type
      @default_root_node_type ||= ArrayTrie
    end

    # The default node type (is the node_type of the default_root_node_type )
    def default_node_type
      default_root_node_type.node_type
    end

    # The default handler ( Derailleur::DefaultRackHandler )
    # See Derailleur::Handler to understand how to build your own
    def default_handler
      @default_handler ||= DefaultRackHandler
    end

    # The default HTTP method dispatcher ( Derailleur::Dispatcher )
    # See Derailleur::Dispatcher if you want a personal one
    def default_dispatcher
      @default_dispatcher ||= Dispatcher
    end

    # An object representing the routes. Usually, it is the root of a Trie
    def routes
      @routes ||= default_root_node_type.new
    end

    # Normalize a path by making sure it starts with '/'
    def normalize(path)
      File.join('/', path)
    end

    # Chunks a path, splitting around '/' separators
    # there always is an empty name
    # 'foo/bar' => ['', 'foo', 'bar']
    def chunk_path(path)
      normalize(path).split('/')
    end

    # Builds a route by appending nodes on the path.
    # The implementation of nodes should create missing nodes on the path.
    # See ArrayTrieNode#<< or HashTrieNode#<<
    # Returns the last node for this path
    def build_route(path)
      current_node = routes
      chunk_path(path).each do |chunk|
        current_node = current_node << chunk
      end
      current_node
    end

    # Return the node corresponding to a given path.  
    # Will (optionally) consecutively yield all the [node, chunk_name]
    # this is useful when you want to interpret the members of the path
    # as a parameter.
    def get_route(path)
      current_node = routes
      chunk_path(path).each do |chunk|
        unless current_node.absorbent?
          current_node = current_node.child_for_name(chunk)
          raise NoSuchRoute, "no such path #{path}" unless current_node
        end
        yield current_node, chunk if block_given?
      end
      current_node
    end


    # Registers an handler for a given path.
    # The path will be interpreted as an absolute path prefixed by '/' .
    #
    # Usually you will not use this method but a method from the 
    # base/application.rb code (with the name of the 
    # HTTP method: e.g. get post put)
    #
    # The method argument is the HTTP method name as a symbol (e.g. :GET)
    # (handler || blk) is the handler set. i.e., if there's both a handler
    # and a block, the block will be ignored.
    #
    # Params is hash of parameters, currently, the only key 
    # looked at is :overwrite to overwrite an handler for an 
    # existing path/method pair.
    #
    # Internally, the path will be created node by node when nodes for this
    # path are missing.
    # A default_dispatcher will be here to map the various HTTP methods for the
    # same path to their respective handlers.
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

    # Split a whole branch of the application at the given path, and graft the
    # branch to the app in second parameter.
    # This method does NOT prevents you from cancelling handlers in the second
    # app if any. Because it does not check for handlers in the receiving
    # branch. Use with care.  See ArrayNode#graft!
    def split_to!(path, app)
      app_node = app.build_route(path)

      split_node = get_route(normalize(path))
      split_node.prune!

      app_node.graft!(split_node)
    end

    # Similar to get route, but also interprets nodes names as keys for a hash.
    # The values in the parameters hash are the string corresponding to the
    # nodes in the path.
    # A specific key is :splat, which correspond to the remaining chunks in the
    # paths.
    # Does NOT take care of key collisions. This should be taken care of at the
    # application level.
    def get_route_with_params(path)
      params = {:splat => []}
      route = get_route(path) do |node, val|
        if node.wildcard?
          params[node.name] = val 
        elsif node.absorbent?
          params[:splat] << val 
        end
      end
      [route, params]
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
  end
end
