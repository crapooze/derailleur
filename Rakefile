
require 'rubygems'
require 'rake/gempackagetask'

$LOAD_PATH.unshift('lib')
require 'derailleur'

spec = Gem::Specification.new do |s|

        s.name = 'derailleur'
        s.rubyforge_project = 'derailleur'
        s.version = Derailleur::VERSION
        s.author = Derailleur::AUTHORS.first
        s.homepage = Derailleur::WEBSITE
        s.summary = "A super-fast Rack web framework"
        s.description = Derailleur::DESCRIPTION
        s.email = "crapooze@gmail.com"
        s.platform = Gem::Platform::RUBY

        s.files = [
          'Rakefile', 
          'TODO', 
          'lib/derailleur.rb',

          'lib/derailleur/base/application.rb',
          'lib/derailleur/base/grease.rb',
          'lib/derailleur/base/context.rb',
          'lib/derailleur/base/handler_generator.rb',

          'lib/derailleur/core/application.rb',
          'lib/derailleur/core/array_trie.rb',
          'lib/derailleur/core/dispatcher.rb',
          'lib/derailleur/core/errors.rb',
          'lib/derailleur/core/handler.rb',
          'lib/derailleur/core/hash_trie.rb',
          'lib/derailleur/core/trie.rb',

          'lib/derailleur/rack/application.rb',
          'lib/derailleur/rack/dispatcher.rb',
          'lib/derailleur/rack/errors.rb',
          'lib/derailleur/rack/handler.rb',
        ]

        s.require_path = 'lib'
        s.bindir = 'bin'
        s.executables = []
        s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_tar = true
end

task :gem => ["pkg/#{spec.name}-#{spec.version}.gem"] do
        puts "generated #{spec.version}"
end


desc "run an example"
task :example, :ex, :server, :port do |t, params|
  path = "./example/#{params[:ex]}.rb"
  servername = params[:server] || 'thin' 
  port = params[:port] || '3000' 
  if File.file? path
    require path
    require 'rack'
    app = Rack::Builder.new {
      run ExampleApplication
    }
    server = Rack::Handler.get(servername)
    server.run(app, :Port => port.to_i)
  else
    puts "no such example: #{path}
    use ls example to see the possibilities"
   
  end
end
