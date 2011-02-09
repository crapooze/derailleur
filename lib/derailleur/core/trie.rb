
module Derailleur
  class TrieNode
    # The name for this node
    attr_reader :name

    # The children of this node
    attr_reader :children

    # The children of this node
    attr_accessor :content

    # The parent of this node, or nil if this node is a root
    attr_accessor :parent

    # This is the default children for the TrieNode 
    # (i.e., we record only the parent)
    # That's why TrieNode is mainly a parent class and should be
    # subclassed.
    class EmptyClass
      def self.empty?
        true
      end
    end

    # Creates a new node whose name and optional parent are set from 
    # the parameters.
    # There is a check wether the parent is absorbent (which disallow childrens)
    # The children is set to EmptyClass, which is a placeholder for subclasses
    # 
    def initialize(name, parent=nil)
      raise ArgumentError, "cannot be the child of #{parent} because it is an absorbent node" if parent and parent.absorbent?
      @parent = parent
      @children = EmptyClass
      set_normal!
      self.name = name
    end

    # sets the name of the node and also does other stuff with special names:
    # - '*' means absorbent
    # - /^:/ means wildcard
    # - otherwise it's normal
    def name=(val)
      set_val = if val 
                  case val
                  when '*'
                    set_absorbent!
                  when /^:/
                    set_wildcard!
                  else
                    set_normal!
                  end
                  val
                else
                  set_normal!
                  nil
                end
      @name = set_val
    end

    private

    # Set this node to be an absorbent one. 
    # In the semantics, an absorbent node means that an
    # entity traversing the trie should stop on this node and should not go any
    # deeper (i.e., an absorbent node is generally a leaf in the tree, although
    # no checking enforces this rule).
    def set_absorbent!  
      set_normal!  
      @absorbent = true 
    end

    # Set this node to be a wildcard one. A wildcard node is a node whose name
    # is an identifier local to the context of the application traversing it.
    # The semantics often is "any name".
    def set_wildcard!
      set_normal!
      @wildcard = true
    end

    # Set this node as normal. That is, cancel any wildcard or absorbent
    # status.
    def set_normal!
      @wildcard = false
      @absorbent = false
    end

    public

    # A wildcard node is a node whose name was set with a trailing ':'
    def wildcard?
      @wildcard
    end

    # An absorbent node is a node which cannot be parent, its name is '*'.
    def absorbent?
      @absorbent
    end

    # A normal node is not absorbent and node wildcard
    def normal?
      (not wildcard?) and (not absorbent?)
    end

    # Compares a node with another, based on their name
    def <=> other
      name <=> other.name
    end

    # A useless node has no content and no children, basically
    # arriving at this point, there's no handler you can ever find.
    def useless?
      content.nil? and children.empty?
    end

    # Returns the root of the tree structure (recursive)
    def root
      parent ? parent.root : self
    end

    # Returns wether or not this node is a root node (i.e., parent is nil)
    def root?
      parent.nil?
    end

    # Returns true wether this node could handoff its position to another one.
    # It is the case if both nodes are normals or both are non-normal.
    def compatible_handoff?(other)
      (normal? and other.normal?) or
      ((not normal?) and (not other.normal?))
    end

    # Raise argument errors if the handoff to other is not licit.
    def verify_hand_off_to(other)
      raise ArgumentError, "cannot hand off to node: #{other} because it is useful" unless other.useless?
      raise ArgumentError, "uncompatible handoff between #{self} and #{other}" unless compatible_handoff?(other)
    end

    # Placeholder for the handoff logic, this method should be overridden by
    # subclasses.
    def hand_off_to!(other)
      verify_hand_off_to(other)
      other.children.replace children
      other.parent = parent
      @children = EmptyClass
      @parent = nil
    end

    # Returns true wether the other node could be grafted over this one.
    # It is the case if both nodes are normals or both are non-normal.
    def compatible_graft?(other)
      (normal? and other.normal?) or
      ((not normal?) and (not other.normal?))
    end

    # Raise argument errors if the grafting of the other node is not licit.
    def verify_graft(other)
      raise ArgumentError, "incompatible grafting" unless compatible_graft?(other)
      raise ArgumentError, "cannot graft a root" if root?
    end

    # Placeholder for the handoff logic, this method should be overridden by
    # subclasses.
    def graft!(other)
      verify_graft(other)
      other.parent = parent
      parent.children.add other
      parent.children.delete self
    end

  end
end
