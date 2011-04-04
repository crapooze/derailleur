
require 'derailleur/core/errors'

module Derailleur
  # Errors raising in Derailleur are subclasses of StandardError.
  # Basically, they have an http_status code. This is useful for the various
  # errors handlers people may write.
  class ApplicationError < StandardError
    def http_status
      500
    end
  end

  # This error is mainly for people implementing handlers wich instanciates
  # other handlers.  The default handler uses it if it tries to instanciate
  # another handler before forwarding to it.
  class InvalidHandler < ApplicationError
  end

  #  A classical kind of not found error in HTTP.
  class NoSuchRoute < ApplicationError
    def http_status
      404
    end
  end

  # This errors shows up when you try to register twice on the same route
  # (i.e., path + verb).
  # Unless you modify the routing on the fly, you should not see this error
  # very often.
  class RouteObjectAlreadyPresent < ApplicationError
  end
end

