
require 'derailleur/core/handler'
require 'derailleur/rack/errors'

module Derailleur
  class Handler
    # Accessors, and to_rack_output for things behaving like RackHandler
    module Rack
      attr_accessor :status, :headers, :page

      # Returns an status, headers, and page array conforming to the Rack
      # specification
      def to_rack_output
        [status, headers, page]
      end

      # Sets to default values the Rack specification fields
      # [200, {}, '']
      def initialize_rack
        @status = 200
        @headers = {}
        @page = ''
      end
    end
  end

  # The rack handler class instanciates the status, headers, and page to
  # default values.
  class RackHandler < Handler
    include Handler::Rack

    def initialize(obj=nil, env=nil, ctx=nil)
      super
      initialize_rack
    end
  end

  # The default rack handler is a handler that does several default things:
  # - if the object respond to to_rack_output (like, another handler)
  #   it will set the handler's env to the current one (the handler must also 
  #   respond to :env= and :ctx=) and call its to_rack_output method
  # - if it's a Proc, it calls the proc passing the env and ctx as 
  #   block parameters
  # - if it's a subclass of Handler, it instantiates it 
  #   (without object, and with the same env and ctx)
  class DefaultRackHandler < RackHandler
    def to_rack_output
      if object.respond_to? :to_rack_output
        do_forward_output
      else
        do_non_forward_output
      end
    end

    def do_forward_output
      object.env = env
      object.ctx = ctx
      object.to_rack_output 
    end

    def do_proc_output
      object.call(env, ctx)
    end

    def do_handler_instantiation_output
      object.new(nil, env, ctx).to_rack_output
    end

    def do_non_forward_output
      ret = case object
            when Proc
              do_proc_output
            when Class
              if object.ancestors.include? RackHandler
                do_handler_instantiation_output
              else
                raise InvalidHandler, "invalid handler: #{object}"
              end
            else
              raise InvalidHandler, "invalid handler: #{object}"
            end
      ret
    end
  end

  # This handler just call the result to a Rack-like application handler
  # (the handler object must conform to the Rack specification)
  # In that case, the Rack application has no view on the ctx variable anymore.
  class RackApplicationHandler < RackHandler
    # Simply delegates the method call to the enclosed object.
    def to_rack_output
      object.call(env)
    end
  end

  # This handler returns the error as text/plain object
  # If the error respond_to http_status, then it will modify the
  # HTTP status code accordingly.
  class InternalErrorHandler < RackHandler
    alias :err :object

    def initialize(err, env, ctx)
      super
      if err.respond_to? :http_status
        @status = err.http_status
      else
        @status = 500
      end
    end

    def headers
      {'Content-Type' => 'text/plain'}
    end

    def page
      [err.class.name,
        err.message,
        err.backtrace].join("\n")
    end
  end
end
