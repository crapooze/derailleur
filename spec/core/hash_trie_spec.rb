
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/hash_trie'

describe HashTrieNode, 'brand new' do
  it "should have an empty Array of children" do
    n = HashTrieNode.new('foo')
    n.children.should be_a(Array)
    n.children.should be_empty
  end
end

describe HashTrieNode, 'appending' do
  it "should create non existing child with correct name" do
    n = HashTrieNode.new('foo')
    child = n << 'bar'
    child.should be_a(TrieNode)
    child.name.should eql('bar')
  end

  it "should create non existing child with correct wildcard name" do
    n = HashTrieNode.new('foo')
    child = n << ':bar'
    child.should be_a(TrieNode)
    child.name.should eql(':bar')
  end

  it "should create non existing child with correct splatting name" do
    n = HashTrieNode.new('foo')
    child = n << '*'
    child.should be_a(TrieNode)
    child.name.should eql('*')
  end

  it "should not recreate previous existing child" do
    n = HashTrieNode.new('foo')
    child1 = n << 'bar'
    child2 = n << 'bar'
    child1.should equal(child2)
  end
end

describe HashTrieNode, 'lookup with normal nodes only' do
  before :each do 
    @node = HashTrieNode.new("hello")
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
    @node.child_for_name('a').should equal(@child1)
    @node.child_for_name('b').should equal(@child2)
    @node.child_for_name('c').should equal(@child3)
  end

  it "should not find a node for a wrong name" do
    @node.child_for_name('wrong').should be_nil
  end
end

describe HashTrieNode, 'with presence of a non normal child' do
  before :each do 
    @node = HashTrieNode.new("hello")
    @child1 = @node << 'a'
    @child2 = @node << ':foo'
    @child3 = @node << 'b'
  end

  it "should have all the children" do
    @node.children.sort.should eql([@child2, @child1, @child3])
  end
end

describe HashTrieNode, 'lookup with a mix of normal and wildcards nodes' do
  before :each do 
    @node = HashTrieNode.new("hello")
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

describe HashTrieNode, 'lookup with a mix of normal and absorbent nodes' do
  before :each do 
    @node = HashTrieNode.new("hello")
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

describe HashTrieNode, 'weird use case' do
  it "should have different name when wildcard despite having similar names" do
    n = HashTrieNode.new('foo')
    child1 = n << ':foo'
    child2 = n << 'foo'
    child1.should_not equal(child2)
  end

  it "should find the same wildcard twice" do
    n = HashTrieNode.new('foo') 
    c1 = n << ':foo'
    c2 = n << ':foo'
    c2.should equal(c1)
  end

  it "should find the same absorbent twice" do
    n = HashTrieNode.new('foo') 
    c1 = n << '*'
    c2 = n << '*'
    c2.should equal(c1)
  end

  it "should disallow different non normal nodes" do
    n = HashTrieNode.new('foo') 
    c1 = n << '*'
    lambda{ c2 = n << ':foo'}.should raise_error(ArgumentError)
  end

  it "should disallow different non normal nodes" do
    n = HashTrieNode.new('foo') 
    c1 = n << ':foo'
    lambda{ c2 = n << ':bar'}.should raise_error(ArgumentError)
    lambda{ c2 = n << '*'}.should raise_error(ArgumentError)
  end
end

describe HashTrieNode, 'recursive mapping' do
  it "should build a nested array, for eah level is an array: [node, *childrens]" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    n2 = n << 'n2'
    n21 = n2 << 'n21'
    n22 = n2 << 'n22'
    n23 = n2 << 'n23'
    n3 = n << 'n3'
    
    expected = ['n', ['n1'], ['n2', ['n21'], ['n22'], ['n23']], ['n3']]

    got = n.tree_map(&:name)

    #level0 tests
    got.first.should eql('n')
    got.include?(['n1']).should be_true
    got.include?(['n3']).should be_true

    #level1 tests
    ary = got.find{|val| val.is_a?(Array) and val.first == 'n2'}
    ary.should_not be_nil
    ary.include?(['n21']).should be_true
    ary.include?(['n22']).should be_true
    ary.include?(['n23']).should be_true
  end
end

describe HashTrieNode, 'pruning' do
  it "should do nothing to prune a root" do
    n = HashTrieNode.new('n')
    lambda { n.prune! }.should_not raise_error
  end

  it "should remove the pruned node, whatever is the kind of node" do
    ['normal', ':wildcard', '*'].each do |name|
      n = HashTrieNode.new('n')
      n1 = n << name
      n1.prune!
      n.children.include?(n1).should be_false
    end
  end

  it "should become a root" do
    ['normal', ':wildcard', '*'].each do |name|
      n = HashTrieNode.new('n')
      n1 = n << name
      n1.prune!
      n1.root?.should be_true
    end
  end

  it "should recursively remove the useless nodes" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_false
  end

  it "should not prune the parents with other children" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n12 = n1 << 'n12'
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_true
  end

  it "should not prune the parents with content" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    n11 = n1 << 'n11'
    n1.content = "content"
    n11.prune!
    n1.children.include?(n11).should be_false
    n.children.include?(n1).should be_true
  end
end

describe HashTrieNode, 'handover' do
  it "should be compatible between two normal nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new('bar')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should be compatible between two absorbent nodes" do
    n1 = HashTrieNode.new('*')
    n2 = HashTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should be compatible between two wildcard nodes" do
    n1 = HashTrieNode.new(':foo')
    n2 = HashTrieNode.new(':bar')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end
  
  it "should be uncompatible between normal and wildcard nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new(':bar')
    n1.compatible_handoff?(n2).should be_false
    n2.compatible_handoff?(n1).should be_false
  end

  it "should be uncompatible between normal and absorbent nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_false
    n2.compatible_handoff?(n1).should be_false
  end

  it "should be compatible between wildcard and absorbent nodes" do
    n1 = HashTrieNode.new(':foo')
    n2 = HashTrieNode.new('*')
    n1.compatible_handoff?(n2).should be_true
    n2.compatible_handoff?(n1).should be_true
  end

  it "should prevent handing over to useful nodes" do
    n = HashTrieNode.new('n')
    other = HashTrieNode.new('foo')
    def other.useless?
      false
    end
    lambda {n.hand_off_to!(other)}.should raise_error(ArgumentError)
  end

  it "should prevent handing over uncompatible handovers" do
    n = HashTrieNode.new('n')
    other = HashTrieNode.new('foo')
    def n.compatible_handoff?(other)
      false
    end
    lambda {n.hand_off_to!(other)}.should raise_error(ArgumentError)
  end

  it "should hand-over the children" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    n2 = n << ':n2'
    other = HashTrieNode.new('other')
    n.hand_off_to!(other)
    other.children.include?(n1).should be_true
    other.children.include?(n2).should be_true
    n.children.should be_empty
  end

  it "should hand-over parent for normal name" do
    n = HashTrieNode.new('n')
    n1 = n << 'n1'
    other = HashTrieNode.new('other')
    n1.hand_off_to!(other)
    n1.parent.should be_nil
    other.parent.should equal(n)
    n.children.include?(n1).should be_false
  end
  
  it "should hand-over parent for wildcards and absorbent" do
    [':n1', '*'].each do |n1name|
      [':other', '*'].each do |othername|
        n = HashTrieNode.new('n')
        n1 = n << n1name
        other = HashTrieNode.new(othername)
        n1.hand_off_to!(other)
        n1.parent.should be_nil
        other.parent.should equal(n)
        n.children.include?(n1).should be_false
      end
    end
  end

  it "should not copy the content" do
    n = HashTrieNode.new('n')
    n.content = :foo
    other = HashTrieNode.new('other')
    n.hand_off_to!(other)
    n.content.should equal(:foo)
    other.content.should be_nil
  end

end

describe HashTrieNode, 'grafting' do
  it "should be compatible between two normal nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new('bar')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should be compatible between two absorbent nodes" do
    n1 = HashTrieNode.new('*')
    n2 = HashTrieNode.new('*')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should be compatible between two wildcard nodes" do
    n1 = HashTrieNode.new(':foo')
    n2 = HashTrieNode.new(':bar')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end
  
  it "should be uncompatible between normal and wildcard nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new(':bar')
    n1.compatible_graft?(n2).should be_false
    n2.compatible_graft?(n1).should be_false
  end

  it "should be uncompatible between normal and absorbent nodes" do
    n1 = HashTrieNode.new('foo')
    n2 = HashTrieNode.new('*')
    n1.compatible_graft?(n2).should be_false
    n2.compatible_graft?(n1).should be_false
  end

  it "should be compatible between wildcard and absorbent nodes" do
    n1 = HashTrieNode.new(':foo')
    n2 = HashTrieNode.new('*')
    n1.compatible_graft?(n2).should be_true
    n2.compatible_graft?(n1).should be_true
  end

  it "should prevent uncompatible grafting" do
    n = HashTrieNode.new('n')
    other = HashTrieNode.new('foo')
    def n.compatible_graft?(other)
      false
    end
    lambda {n.graft!(other)}.should raise_error(ArgumentError)
  end

  it "should graft the full branch" do
    n = HashTrieNode.new('n')
    n1 = n << ':n1'
    n2 = n1 << 'n2'
    other = HashTrieNode.new('other')
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
    n = HashTrieNode.new('n')
    n.content = :foo
    other = HashTrieNode.new('other')
    n.hand_off_to!(other)
    n.content.should equal(:foo)
    other.content.should be_nil
  end
end

describe HashTrie, 'a root for HashTrieNodes' do
  it "should be a root, and empty children"  do
    n = HashTrie.new
    n.name.should be_nil
    n.root?.should be_true
    n.children.empty?.should be_true
  end

  it "should be insensitive to pruning" do
    n = HashTrie.new
    foo = n << 'foo'
    bar = n << ':bar'
    n.prune!
    n.children.include?(foo).should be_true
    n.children.include?(bar).should be_true
  end
end
