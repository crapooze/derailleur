
require 'derailleur/core/trie'

module Derailleur
  class ArrayTrieNode < TrieNode
    # A fallback children, in case there is no child matching, this
    # one is found.
    attr_accessor :fallback_child

    # An array of normal chidrens
    attr_reader :normal_children

    def initialize(name, parent=nil)
      super
      @normal_children = []
    end

    # List the children, including the fallback_child (in last position) if any
    def children
      ary = normal_children.dup
      ary << fallback_child if fallback_child
      ary
    end

    # Tries adding a new children built from the name
    # * if the name is for a normal child
    #   * if there already is a normal_children node with this name, returns it
    #   * otherwise creates one
    # * if the name is for a fallback child
    #   * if there is no fallback child, creates one
    #   * otherwise
    #     * if the wording are identical, will just return the existing one
    #     * if the wording are different, will raise an ArgumentError
    def << name
      node = child_with_exact_name(name)
      if node
        node
      else
        new_node = ArrayTrieNode.new(name, self)
        ret = if new_node.normal?
                normal_children << new_node
                new_node
              elsif fallback_child
                raise ArgumentError, "there already is a fallback child in #{self}" unless fallback_child.name == new_node.name
                fallback_child
              else
                @fallback_child = new_node
              end
        ret
      end
    end

    # Returns the normal child with the name passed in parameter
    # or nil if there is no such child
    def child_with_exact_name(name)
      normal_children.find{|n| n.name == name}
    end

    # Returns the child whose name match the parameter, 
    # or the fallback one, or nil if there is no such child
    def child_for_name(name)
      child = child_with_exact_name(name)
      if child
        child
      else
        fallback_child
      end
    end

    # Like Enumerable#map, but recursively creates a new array per child
    # it looks like this:
    # [root, [child1, [child11, child12]], [child2]]
    def tree_map(&blk)
      children.inject([yield(self)]) do |trunk, child| 
        trunk << child.tree_map(&blk)
      end
    end

    # Pruning the node means cutting the tree by removing the link between this
    # node and its parent.  The pruned node thus becomes a root and could be
    # placed somewhere else.  References to this node in the former parent node
    # are cleaned during the process.  The process of pruning is recursive and
    # stops whenever it encounters a not useless node (see useless?)
    def prune!
      return if root? #you cannot prune the root
      if normal?
        parent.normal_children.delete(self)
      else
        parent.fallback_child = nil
      end
      old_parent = parent
      @parent = nil
      old_parent.prune! if old_parent.useless?
    end

    # Hands off the role of this node to another, single, independent, simple,
    # and useless node (as opposed to useful and complex ones, e.g., a complete
    # branch of the tree). This is mainly useful for doing a sort of reset on
    # the node's state without caring much about the content of the current
    # node, but you only care about the state of the new node. You can see it
    # like (or actually perform) "changing the class" of the node on the fly.
    #
    # To avoid weird situations, hand off must be licit:
    # - the other node must be useless to avoid losing its useful content
    # - the nodes must be compatible to prevent weird situations (see
    # compatible_handoff?)
    #
    # Otherwise, an error explaining why the handoff is not licit will be
    # raised.
    #
    # If the handoff can take place, it happens as follow:
    # - the other node will copy current's children
    # - this node will clear its references to its children
    #
    # Then, if there is a parent to current node, parent's reference will be modified
    # to point to the replacing node. Finally, the other node will copy
    # current's parent, and the reference to the parent will be cleared in this
    # node.
    def hand_off_to!(other)
      verify_hand_off_to(other)

      other.normal_children.replace normal_children
      other.fallback_child = fallback_child
      @normal_children = []
      @fallback_child = nil
      if parent
        if normal?
          parent.normal_children.delete(self)
          parent.normal_children << other
        else
          parent.fallback_child = other
        end
        other.parent = parent
        @parent = nil
      end
    end

    # grafting another node means replacing this node in the tree by the other
    # node, including its hierarchy (i.e., you can place branches).  this
    # process works by replacing the reference to this node by the other node
    # in this parent this process also updates the other node's parent
    #
    # one can only graft normal node in place of normal nodes, and vice versa,
    # an incompatible grafting will raise an ArgumentError
    # moreover, because of the semantics, grafting to a root will raise an error
    #
    # see-also compatible_graft?
    def graft!(other)
      verify_graft(other)

      other.parent = parent
      if other.normal?
        parent.normal_children << other
        parent.normal_children.delete(self)
      else
        parent.fallback_child = other
      end
    end
  end

  class ArrayTrie < ArrayTrieNode
    def self.node_type
      ArrayTrieNode
    end

    def initialize
      @parent = nil
      @normal_children = []
    end

    def name
      nil
    end

    def prune!
      nil
    end
  end
end
