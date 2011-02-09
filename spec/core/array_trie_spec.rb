
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/array_trie'

describe ArrayTrieNode, 'brand new' do
  it "should have an empty Array of children" do
    n = ArrayTrieNode.new('foo')
    n.children.should be_a(Array)
    n.children.should be_empty
  end
end

describe ArrayTrieNode, 'appending' do
  it "should create non existing child with correct name" do
    n = ArrayTrieNode.new('foo')
    child = n << 'bar'
    child.should be_a(TrieNode)
    child.name.should eql('bar')
  end

  it "should create non existing child with correct wildcard name" do
    n = ArrayTrieNode.new('foo')
    child = n << ':bar'
    child.should be_a(TrieNode)
    child.name.should eql(':bar')
  end

  it "should create non existing child with correct splatting name" do
    n = ArrayTrieNode.new('foo')
    child = n << '*'
    child.should be_a(TrieNode)
    child.name.should eql('*')
  end

  it "should not recreate previous existing child" do
    n = ArrayTrieNode.new('foo')
    child1 = n << 'bar'
    child2 = n << 'bar'
    child1.should equal(child2)
  end
end

describe ArrayTrieNode, 'lookup with normal nodes only' do
  before :each do 
    @node = ArrayTrieNode.new("hello")
    @child1 = @node << 'a'
    @child2 = @node << 'b'
    @child3 = @node << 'c'
  end

  after :each do
    @node = nil
    @child1 = nil
    @child2 = nil
    @child3 = nil
  end

  it "should find the exact child node" do
    @node.child_with_exact_name('a').should equal(@child1)
    @node.child_with_exact_name('b').should equal(@child2)
    @node.child_with_exact_name('c').should equal(@child3)

    @node.child_for_name('a').should equal(@child1)
    @node.child_for_name('b').should equal(@child2)
    @node.child_for_name('c').should equal(@child3)
  end

  it "should not find a node for a wrong name" do
    @node.child_with_exact_name('wrong').should be_nil
    @node.child_for_name('wrong').should be_nil
  end
end

describe ArrayTrieNode, 'with presence of a non normal child' do
  before :each do 
    @node = ArrayTrieNode.new("hello")
    @child1 = @node << 'a'
    @child2 = @node << ':foo'
    @child3 = @node << 'b'
  end

  it "should not be counted in the normal children" do
    @node.normal_children.should eql([@child1, @child3])
  end

  it "should have a fallback child" do
    @node.fallback_child.should eql(@child2)
  end

  it "should have all the children" do
    @node.children.should eql([@child1, @child3, @child2])
  end
end

describe ArrayTrieNode, 'lookup with a mix of normal and wildcards nodes' do
  before :each do 
    @node = ArrayTrieNode.new("hello")
    @child1 = @node << 'a'
    @child2 = @node << ':foo'
    @child3 = @node << 'b'
  end

  after :each do
    @node = nil
    @child1 = nil
    @child2 = nil
    @child3 = nil
  end

  it "should find the node with exact name if added before the wildcard" do
    @node.child_for_name('a').should equal(@child1)
  end

  it "should find the node with exact name if added after the wildcard" do
    @node.child_for_name('b').should equal(@child3)
  end

  it "should fallback to the wildcard one" do
    @node.child_for_name('inexistant').should equal(@child2)
  end
end

describe ArrayTrieNode, 'lookup with a mix of normal and absorbent nodes' do
  before :each do 
    @node = ArrayTrieNode.new("hello")
    @child1 = @node << 'a'
    @child2 = @node << '*'
    @child3 = @node << 'b'
  end

  after :each do
    @node = nil
    @child1 = nil
    @child2 = nil
    @child3 = nil
  end

  it "should find the node with exact name if added before the wildcard" do
    @node.child_for_name('a').should equal(@child1)
  end

  it "should find the node with exact name if added after the wildcard" do
    @node.child_for_name('b').should equal(@child3)
  end

  it "should fallback to the wildcard one" do
    @node.child_for_name('inexistant').should equal(@child2)
  end
end

describe ArrayTrieNode, 'weird use case' do
  it "should have different name when wildcard despite having similar names" do
    n = ArrayTrieNode.new('foo')
    child1 = n << ':foo'
    child2 = n << 'foo'
    child1.should_not equal(child2)
  end

  it "should find the same wildcard twice" do
    n = ArrayTrieNode.new('foo') 
    c1 = n << ':foo'
    c2 = n << ':foo'
    c2.should equal(c1)
  end

  it "should find the same absorbent twice" do
    n = ArrayTrieNode.new('foo') 
    c1 = n << '*'
    c2 = n << '*'
    c2.should equal(c1)
  end

  it "should disallow different non normal nodes" do
    n = ArrayTrieNode.new('foo') 
    c1 = n << '*'
    lambda{ c2 = n << ':foo'}.should raise_error(ArgumentError)
  end

  it "should disallow different non normal nodes" do
    n = ArrayTrieNode.new('foo') 
    c1 = n << ':foo'
    lambda{ c2 = n << ':bar'}.should raise_error(ArgumentError)
    lambda{ c2 = n << '*'}.should raise_error(ArgumentError)
  end
end

describe ArrayTrieNode, 'recursive mapping' do
  it "should build a nested array, for eah level is an array: [node, *childrens]" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    n2 = n << 'n2'
    n21 = n2 << 'n21'
    n22 = n2 << 'n22'
    n23 = n2 << 'n23'
    n3 = n << 'n3'
    
    expected = ['n', ['n1'], ['n2', ['n21'], ['n22'], ['n23']], ['n3']]

    n.tree_map(&:name).should eql(expected)
  end
end

describe ArrayTrieNode, 'pruning' do
  it "should do nothing to prune a root" do
    n = ArrayTrieNode.new('n')
    lambda { n.prune! }.should_not raise_error
  end

  it "should remove the pruned node, whatever is the kind of node" do
    ['normal', ':wildcard', '*'].each do |name|
      n = ArrayTrieNode.new('n')
      n1 = n << name
      n1.prune!
      n.children.include?(n1).should be_false
    end
  end

  it "should become a root" do
    ['normal', ':wildcard', '*'].each do |name|
      n = ArrayTrieNode.new('n')
      n1 = n << name
      n1.prune!
      n1.root?.should be_true
    end
  end

  it "should recursively remove the useless nodes" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_false
  end

  it "should not prune the parents with other children" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n12 = n1 << 'n12'
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_true
  end

  it "should not prune the parents with content" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n1.content = "content"
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_true
  end
end

describe ArrayTrieNode, 'handover' do
  it "should be compatible between two normal nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new('bar')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should be compatible between two absorbent nodes" do
    n1 = ArrayTrieNode.new('*')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should be compatible between two wildcard nodes" do
    n1 = ArrayTrieNode.new(':foo')
    n2 = ArrayTrieNode.new(':bar')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end
  
  it "should be uncompatible between normal and wildcard nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new(':bar')
    n1.compatible_handoff?(n2).should be_false
    n2.compatible_handoff?(n1).should be_false
  end

  it "should be uncompatible between normal and absorbent nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_false
    n2.compatible_handoff?(n1).should be_false
  end

  it "should be compatible between wildcard and absorbent nodes" do
    n1 = ArrayTrieNode.new(':foo')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should prevent handing over to useful nodes" do
    n = ArrayTrieNode.new('n')
    other = ArrayTrieNode.new('foo')
    def other.useless?
      false
    end
    lambda {n.hand_off_to!(other)}.should raise_error(ArgumentError)
  end

  it "should prevent handing over uncompatible handovers" do
    n = ArrayTrieNode.new('n')
    other = ArrayTrieNode.new('foo')
    def n.compatible_handoff?(other)
      false
    end
    lambda {n.hand_off_to!(other)}.should raise_error(ArgumentError)
  end

  it "should hand-over the children" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    n2 = n << ':n2'
    other = ArrayTrieNode.new('other')
    n.hand_off_to!(other)
    other.children.include?(n1).should be_true
    other.children.include?(n2).should be_true
    n.children.should be_empty
  end

  it "should hand-over parent for normal name" do
    n = ArrayTrieNode.new('n')
    n1 = n << 'n1'
    other = ArrayTrieNode.new('other')
    n1.hand_off_to!(other)
    n1.parent.should be_nil
    other.parent.should equal(n)
    n.children.include?(n1).should be_false
  end
  
  it "should hand-over parent for wildcards and absorbent" do
    [':n1', '*'].each do |n1name|
      [':other', '*'].each do |othername|
        n = ArrayTrieNode.new('n')
        n1 = n << n1name
        other = ArrayTrieNode.new(othername)
        n1.hand_off_to!(other)
        n1.parent.should be_nil
        other.parent.should equal(n)
        n.children.include?(n1).should be_false
      end
    end
  end

  it "should not copy the content" do
    n = ArrayTrieNode.new('n')
    n.content = :foo
    other = ArrayTrieNode.new('other')
    n.hand_off_to!(other)
    n.content.should equal(:foo)
    other.content.should be_nil
  end

end

describe ArrayTrieNode, 'grafting' do
  it "should be compatible between two normal nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new('bar')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should be compatible between two absorbent nodes" do
    n1 = ArrayTrieNode.new('*')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should be compatible between two wildcard nodes" do
    n1 = ArrayTrieNode.new(':foo')
    n2 = ArrayTrieNode.new(':bar')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end
  
  it "should be uncompatible between normal and wildcard nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new(':bar')
    n1.compatible_graft?(n2).should be_false
    n2.compatible_graft?(n1).should be_false
  end

  it "should be uncompatible between normal and absorbent nodes" do
    n1 = ArrayTrieNode.new('foo')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_graft?(n2).should be_false
    n2.compatible_graft?(n1).should be_false
  end

  it "should be compatible between wildcard and absorbent nodes" do
    n1 = ArrayTrieNode.new(':foo')
    n2 = ArrayTrieNode.new('*')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should prevent uncompatible grafting" do
    n = ArrayTrieNode.new('n')
    other = ArrayTrieNode.new('foo')
    def n.compatible_graft?(other)
      false
    end
    lambda {n.graft!(other)}.should raise_error(ArgumentError)
  end

  it "should graft the full branch" do
    n = ArrayTrieNode.new('n')
    n1 = n << ':n1'
    n2 = n1 << 'n2'
    other = ArrayTrieNode.new('other')
    m1 = other << 'm1'
    m2 = m1 << ':m2'
    n2.graft!(other)
    n1.children.include?(n2).should be_false
    n1.children.include?(other).should be_true
    other.parent.should eql(n1)
    m1.root.should eql(n)
    m2.root.should eql(n)
  end

  it "should not copy the content" do
    n = ArrayTrieNode.new('n')
    n.content = :foo
    other = ArrayTrieNode.new('other')
    n.hand_off_to!(other)
    n.content.should equal(:foo)
    other.content.should be_nil
  end
end

describe ArrayTrie, 'a root for ArrayTrieNodes' do
  it "should be a root, and empty children"  do
    n = ArrayTrie.new
    n.name.should be_nil
    n.root?.should be_true
    n.children.empty?.should be_true
  end

  it "should be insensitive to pruning" do
    n = ArrayTrie.new
    foo = n << 'foo'
    bar = n << ':bar'
    n.prune!
    n.children.include?(foo).should be_true
    n.children.include?(bar).should be_true
  end
end
