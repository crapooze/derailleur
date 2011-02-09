
$LOAD_PATH << 'lib'

require 'derailleur'
require 'derailleur/core/handler'

class MyHandler < Derailleur::RackHandler
  attr_writer :message
  def message
    @message || "class message"
  end
  def to_rack_output
    [200, {}, message]
  end
end

module ExampleApplication
  extend Derailleur::Application

  examples =  ["/block", "/handler-instance", "/handler-class", 
    "/rack-lobster", "/parameter/foo", "/splat/a/blob", 
    "/extension.foobar",
    "/extension.rb",
  ]

  get('/') do
    [200, {}, examples.map{|e| "<a href=\"#{e}\">#{e}</a>"}.join("\n")]
  end

  get('/extension') do |env, ctx|
    [200, {}, "extension: #{File.extname(env['PATH_INFO'])}"]
  end

  get('/block') do
    [200, {}, "block"]
  end

  my_handler = MyHandler.new
  my_handler.message = ('instance message')

  get('/handler-instance', my_handler)

  get('/handler-class', MyHandler)

  get('/raise') do
    raise StandardError, "raised for the demo"
  end

  require 'rack'
  require 'rack/lobster'
  rack_app = Rack::Builder.new do
    use Rack::Lint
    run Rack::Lobster.new
  end

  get('/rack-lobster', Derailleur::RackApplicationHandler.new(rack_app))

  get('/long/long/path', 'really long path')

  get('/parameter/:value') do |env,ctx|
    [200, {}, "parameter: #{ctx['derailleur.params'][':value']}"]
  end

  get('/splat/*') do |env, ctx|
    [200, {}, "splats: #{ctx['derailleur.params'][:splat].inspect}"]
  end
end
