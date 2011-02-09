
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'derailleur/core/trie'

describe TrieNode, 'naming scheme' do
  it "has a name when created" do
    t = TrieNode.new('foo')
    t.name.should eql('foo')
  end

  it "should be a normal node with the name 'foo'" do
    t = TrieNode.new('foo')
    t.normal?.should be_true
    t.absorbent?.should be_false
    t.wildcard?.should be_false
  end

  it "should be an absorbent node with the name '*'" do
    t = TrieNode.new('*')
    t.normal?.should be_false
    t.absorbent?.should be_true
    t.wildcard?.should be_false
  end

  it "should be an absorbent node with the name ':foo'" do
    t = TrieNode.new(':foo')
    t.normal?.should be_false
    t.absorbent?.should be_false
    t.wildcard?.should be_true
  end

  it "should NOT rename itself 'foo' with the name ':foo'" do
    t = TrieNode.new(':foo')
    t.name.should eql(':foo')
  end
end

describe TrieNode, 'usefulness' do
  it "should be useless when brand new" do
    t = TrieNode.new('foo')
    t.useless?.should be_true
  end

  it "should not be useless with some content" do
    t = TrieNode.new('foo')
    t.content = :bar
    t.useless?.should be_false
  end
end

describe TrieNode, 'comparison' do
  before :all do
    @t1 = TrieNode.new('foo')
    @t2 = TrieNode.new('bar')
    @t1bis = TrieNode.new('foo')
  end

  it "should come later than in lexicographic order" do
    (@t1 <=> @t2).should eql(1)
  end

  it "should come later than in lexicographic order" do
    (@t2 <=> @t1).should eql(-1)
  end

  it "should come at the same time in lexicographic order" do
    (@t1bis <=> @t1).should eql(0)
    (@t1 <=> @t1bis).should eql(0)
  end
end

describe TrieNode, 'parenting' do
  it "should be a root node when new without parent" do
    t = TrieNode.new('foo')
    t.root?.should be_true
  end

  it "should have empty children when brand new" do
    t = TrieNode.new('foo')
    t.children.should be_empty
  end

  it "should record the parent when new with parent" do
    parent = TrieNode.new('foo')
    t = TrieNode.new('foo', parent)
    t.parent.should eql(parent)
  end

  it "should find the root event when nested" do
    parent0 = TrieNode.new('foo')
    parent1 = TrieNode.new('foo', parent0)
    t = TrieNode.new('foo', parent1)
    parent0.root?.should be_true
    parent1.root?.should be_false
    t.root?.should be_false
    parent0.root.should eql(parent0)
    parent1.root.should eql(parent0)
    t.root.should eql(parent0)
  end

  it "should always have empty children (to encourage subclassing)" do
    parent = TrieNode.new('foo')
    t = TrieNode.new('foo', parent)
    parent.children.should be_empty
  end

  it "should prevent absorbent nodes to be parents" do
    absorbent = TrieNode.new('*')
    lambda{TrieNode.new('foo', absorbent)}.should raise_error(ArgumentError)
  end
end
