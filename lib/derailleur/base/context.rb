
module Derailleur
  # A context is the place where we handle an incoming HTTP Request.
  # much like a Rack application, it has an env and the result must
  # be an array of three items: [status, headers, content]
  # The content is just an instance_evaluation of a callback passed during
  # initialization.
  class Context
    # The Rack environment
    attr_reader :env

    # The Derailleur context
    attr_reader :ctx

    # A hash representing the HTTP response's headers
    attr_reader :headers

    # The HTTP response's status
    attr_accessor :status

    # The body of the HTTP response, must comply with Rack's specification
    attr_accessor :content

    # The block of code that will be instance_evaled to produce the HTTP
    # response's body
    attr_reader :blk

    def initialize(env, ctx, &blk)
      @status = 200
      @env = env
      @ctx = ctx
      @blk = blk
      @content = nil
      @headers = {'Content-Type' => 'text/plain'}
    end

    # Simply instance_evaluates the block blk in the context of self
    def evaluate!
      @content = instance_eval &blk
    end

    # The Derailleur::Application for this context
    def app
      ctx['derailleur']
    end

    # The parameters as parsed from the URL/HTTP-path chunks
    def params
      ctx['derailleur.params']
    end

    # Method that wraps the status, headers and content into an array
    # for Rack specification.
    def result
      [status, headers, content]
    end

    # Returns the extension name of the HTTP path
    def extname
      File.extname(env['PATH_INFO'])
    end
  end
end
