
$LOAD_PATH << 'lib'
require 'derailleur'
require 'derailleur/core/hash_trie'

# This example creates 10k routes, you can run
# ab against it and it should beat sinatra for the same routes,
# or even sinatra with wildcards/regexp routes
module ExampleApplication
  extend Derailleur::Application::RackApplication
  self.default_root_node_type = Derailleur::HashTrie #=> 700Mo

  100.times do |t|
    10.times do |u|
      10.times do |v|
        path = "/foo/#{t}/bar/#{u}/baz/#{v}"
        text = "Foo #{t} - Bar #{u} - Baz #{v}"
        get(path) do
          [200, {'Content-Type' => 'text/plain'}, text]
        end
      end
    end
  end
end
