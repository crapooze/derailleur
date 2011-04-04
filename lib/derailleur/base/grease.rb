
require 'derailleur/base/application'
require 'derailleur/base/handler_generator'

module Derailleur
  # The Grease is the module that helps you code at a high level,
  # with blocks.
  # Basically, including this method in a class makes the HTTP 
  # methods definition available as registrations.
  # Then, instanciating the class, it will actually register the routes
  # in the objects. Including Grease will redefine the "initialize method",
  # do do not include Grease after defining it. Do the opposite.
  # See also Grease#initialize_HTTP (you should call it if you don't use 
  # Grease's initialize method.
  module Grease
    include Derailleur::Application::RackApplication

    Registration = Struct.new(:sym, :path, :handler)

    def self.included(klass)
      klass.extend ClassMethods
    end

    # Transform registration definitions into actual registrations.
    def register_registrations_of(obj)
      obj.registrations.each do |reg|
        send(reg.sym, reg.path, reg.handler)
      end
    end

    # Initialiazes HTTP routes by transforming all the registration definitions
    # in the class of the object into itself.
    def initialize_HTTP
      register_registrations_of(self.class)
    end

    # If there is no initializer, will create one.
    # If there is one, then it will try to call super.
    # As a result include this module into classes *before* defining initialize,
    # or in classes in which you don't care about initialize.
    def initialize(*args, &blk)
      super
      initialize_HTTP
    end

    module ClassMethods
      # Copies the registrations of an object.
      # no check is done on duplicate registrations.
      def inherit_HTTP_method(mod)
        mod.registrations.each do |reg|
          registrations << reg.dup
        end
      end

      # Includes a module and then copies its registrations with
      # inherit_HTTP_method
      def include_and_inherit_HTTP_method(mod)
        include mod
        inherit_HTTP_method(mod)
      end

      # Returns (and create if needed) the list of registrations
      def registrations
        @registrations ||= []
      end

      attr_writer :handler_generator

      # The class to use to create handlers that will catch requests.
      def handler_generator
        @handler_generator ||= Derailleur::HandlerGenerator
      end

      # Sets a specification to registers a handler at the given path and HTTP
      # request "GET".  For the default handler_generator
      # (Derailleur::HandlerGenerator), the block blk will be evaluated in a
      # Derailleur::Context .
      def get(path, params=nil, &blk) 
        registrations << Registration.new(:get, path, 
                                          handler_generator.for(params, &blk))
      end

      # Same as get but for HEAD
      def head(path, params=nil, &blk)
        registrations << Registration.new(:head, path, params,
                                          handler_generator.for(params, &blk))
      end

      # Same as get but for POST
      def post(path, params=nil, &blk)
        registrations <<  Registration.new(:post, path, params,
                                           handler_generator.for(params, &blk))
      end

      # Same as get but for PUT
      def put(path, params=nil, &blk)
        registrations <<  Registration.new(:put, path, params,
                                           handler_generator.for(params, &blk))
      end

      # Same as get but for DELETE
      def delete(path, params=nil, &blk)
        registrations <<  Registration.new(:delete, path, params,
                                           handler_generator.for(params, &blk))
      end
    end
  end
end
