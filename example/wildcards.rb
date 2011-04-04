
$LOAD_PATH << 'lib'

require 'derailleur/base/application'
require 'derailleur/core/hash_trie'

module ExampleApplication
  extend Derailleur::RackApplication

  self.default_root_node_type = Derailleur::HashTrie

  get('/') do |env|
    [200, {}, "hello"]
  end

  get("/foo/:u/bar/:t/baz/:v") do |env, ctx|
    params = ctx['derailleur.params']
    [200, {}, "Foo #{params[':u']} - Bar #{params[':t']} - Baz #{params[':v']}"]
  end
end
