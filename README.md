# Derailleur #
Derailleur was initially a Rack-only module.
Now some cleaning has been done (still ongoing), and Derailleur-core can be used wherever paths mappings are involved.

# Derailleur for Rack applications #

The life of an HTTP incoming request is the following (in the case where everything works):

* Rack calls the Derailleur application with the request
* Derailleur follows the route and find the node of the request's URL
* Derailleur gets dispatcher for the node
* Derailleur gets the handler from the dispatcher and the HTTP verb (GET, POST, ...)
* Derailleur builds an internal handler that will use the dispatcher's handler
* Derailleur calls this handlers
* Rack forwards the response

## Routing URL in Derailleur ##

Routing is the key innovation of Derailleur, Derailleur by default uses a kind
of Tree structure (actually it's closer to a Radix-Tree if you prefer, but the
labels are on the nodes, not on the edges).

The alphabet used in Derailleur is not a per-letter, but a per-url-atom one. A
URL atom is the string between two consecutive '/' separators.  The advantage
of the Trie is that the route lookup is faster than iterating on a list, like
usually done in Sinatra, Rails, or Rack.  Another advantage is the storing
size, which takes into account the redundancies usually found in the URL routes.
Moreover, with a Trie, it becomes easy to insert or remove a whole part of the
routing structure.

Each node of the trie may have an object attached to it. Derailleur puts
Dispatchers inside the nodes.

## Dispatching HTTP requests ##

A Dispatcher is a simple object that associates HTTP verbs like GET, POST to
another object (which usually is a kind of handler, a proc etc.). It can also
holds a default handler in case the verb is not explictly hold.

The reason why Derailleur first look at the route then at the verb, is for the
route lookup to be more efficiently.

## Handling HTTP requests ##

There are conceptually two kinds of handling mechanism in Derailleur:

* routing handler generator, which is a low level handler that developpers do not usually touch
* application handler, which is what a developper writes

### Application Handler ###

Application handlers in Derailleur are similar to Rack applications. 
To be a compliant application handler, you must:

* Respond to :to_rack_output (instead of :call for Rack)
* Assume that no-parameters are passed to the :to_rack_output method (instead of the Rack environment hash)
* You must return an array like in the Rack specification (i. e., an array of three elements, with a status code, a hash of HTTP headers, and the body responding to :each)

### Routing Handler generator ###

The routing handler generator is slightly different:

* The routing handler generator responds to :new
* Three parameters are passed to :new 
  * the handler object associated to the application node for the HTTP incoming request
  * the Rack environment
  * the application context hash with three references:
    * derailleur – current Derailleur application
    * derailleur.node – the application node for the HTTP incoming request
    * derailleur.params – the route parameters if any wildcard/splat substitution happened
* The result of :new complies to the application handlers specification

### The DefaultHandler class ###


### The ErrorHandler class ###


### The RackApplicationHandler class ###

# Derailleur for non-Rack applications #
