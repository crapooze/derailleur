
require 'derailleur/core/application'

module Derailleur
  module Application
    # registers a handler for the GET HTTP method
    # the handler is either content OR the passed block
    # if content is true and there is a block, then the handler will be the content
    # params is a hash of parameters, the only parameter supported is:
    # * :overwrite , if true, then you can rewrite a handler
    def get(path, content=nil, params={}, &blk)
      register_route(path, :GET, content, params, &blk)
    end

    # removes a handler for the GET HTTP method
    def unget(path)
      unregister_route(path, :GET)
    end

    # registers a handler for the HEAD HTTP method
    # see get for the use of parameters
    def head(path, content=nil, params={}, &blk)
      register_route(path, :HEAD, content, params, &blk)
    end

    # removes a handler for the HEAD HTTP method
    def unhead(path)
      unregister_route(path, :HEAD)
    end

    # registers a handler for the POST HTTP method
    # see get for the use of parameters
    def post(path, content=nil, params={}, &blk)
      register_route(path, :POST, content, params, &blk)
    end

    # removes a handler for the POST HTTP method
    def unpost(path)
      unregister_route(path, :POST)
    end

    # registers a handler for the PUT HTTP method
    # see get for the use of parameters
    def put(path, content=nil, params={}, &blk)
      register_route(path, :PUT, content, params, &blk)
    end

    # removes a handler for the PUT HTTP method
    def unput(path)
      unregister_route(path, :PUT)
    end

    # registers a handler for the DELETE HTTP method
    # see get for the use of parameters
    def delete(path, content=nil, params={}, &blk)
      register_route(path, :DELETE, content, params, &blk)
    end

    # removes a handler for the DELETE HTTP method
    def undelete(path)
      unregister_route(path, :DELETE)
    end

    #no TRACE CONNECT
  end
end
