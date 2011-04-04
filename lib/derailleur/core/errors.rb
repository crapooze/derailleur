
module Derailleur
  # Errors raising in Derailleur are subclasses of StandardError.
  class ApplicationError < StandardError
  end

  #  A classical kind of not found error 
  class NoSuchRoute < ApplicationError
  end

  # This errors shows up when you try to register twice on the same route
  # (i.e., path + verb).
  # Unless you modify the routing on the fly, you should not see this error
  # very often.
  class RouteObjectAlreadyPresent < ApplicationError
  end
end
