
require 'derailleur/core/trie'

module Derailleur
  class HashTrieNode < TrieNode
    attr_reader :children_hash

    def initialize(name, parent=nil)
      super
      @children_hash = {}
    end

    def children
      ret = @children_hash.values
      ret << @children_hash.default if @children_hash.default
      ret
    end

    def << name
      node = exact_child_for_name(name)
      if node
        node
      else
        new_node = HashTrieNode.new(name, self)
        ret = if new_node.normal?
                children_hash[name] = new_node
              elsif children_hash.default
                raise ArgumentError, "there already is a fallback child in #{self}" unless children_hash.default.name == new_node.name
                children_hash.default
              else
                children_hash.default = new_node
              end
        ret
      end
    end

    def exact_child_for_name(name)
      children_hash.values.find{|v| v.name == name}
    end

    def child_for_name(name)
      children_hash[name]
    end

    def tree_map(&blk)
      children_hash.values.inject([yield(self)]) do |trunk, child| 
        trunk << child.tree_map(&blk)
      end
    end

    # pruning an already pruned node will crash: it has no parent already
    # also prunes recursively on useless parents
    # will stop naturally on roots because they have an overloaded prune!
    def prune!
      return if root?
      if normal?
        parent.children_hash.delete(name)
      else
        parent.children_hash.default = nil
      end
      old_parent = parent
      @parent = nil
      old_parent.prune! if old_parent.useless?
    end

    def hand_off_to!(other)
      verify_hand_off_to(other)

      other.children_hash.replace @children_hash
      @children_hash = {}
      if parent
        if normal?
          parent.children_hash[name] = other
        else
          parent.children_hash.default = @children_hash.default
        end
        other.parent = parent
        @parent = nil
      end
    end

    def graft!(other)
      verify_graft(other)

      other.parent = parent
      if other.normal?
        parent.children_hash[name] = other
      else
        parent.children_hash.default = other
      end
    end
  end

  class HashTrie < HashTrieNode
    def self.node_type
      HashTrieNode
    end

    def initialize
      @parent = nil
      @children_hash = {}
    end

    def name
      nil
    end

    def prune!
      nil
    end
  end
end
