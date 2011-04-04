
require 'derailleur/core/errors'
require 'derailleur/core/array_trie'

module Derailleur
  # In Derailleur, an application is an object extending the Application
  # module. 
  module Application

    attr_writer :default_root_node_type
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
    def get_route_silent(path)
      current_node = routes
      chunk_path(path).each do |chunk|
        unless current_node.absorbent?
          current_node = current_node.child_for_name(chunk)
          return nil unless current_node
        end
        yield current_node, chunk if block_given?
      end
      current_node
    end

    # Same as get_route_silent but raise a 
    # NoSuchRoute error if there is no matching route.
    def get_route(path)
      node = if block_given?
               get_route_silent(path) do |node,chunk|
                 yield node, chunk 
               end
             else
               get_route_silent(path) 
             end
      raise NoSuchRoute, "no such path #{path}" unless node
      node
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
  end
end
