
$LOAD_PATH << 'lib'
require 'derailleur/base/application'

class TextHandler 
  attr_accessor :text
  attr_writer :env, :ctx
  def initialize(text)
    @text = text
  end
  def to_rack_output
    [200, {}, text]
  end
end

module ExampleApplication
  extend Derailleur::RackApplication

  def self.embedded_arrays_to_string(map, idx=0, total='')
    str = ' ' * total.size
    map.each do |ary|
      unless ary.first.is_a? Array
        val, token = *ary
        total += val.to_s
        str << '/' + val.to_s + " (#{total})" + " #{token}"
      else
        val = ary
        str << "\n"
        str << embedded_arrays_to_string(val, idx+1, total + '/')
      end
    end
    str
  end

  get('/') do
    map = routes.tree_map do |node|
      [node.name, node.content ? 'Handled' : 'Not-Handled' ]
    end
    str = embedded_arrays_to_string(map)
    begin
      unget('/foo/bar/baz0')
    rescue Derailleur::NoSuchRoute
      #i.e., we already removed it
      unget('/foo/bar')
    end
    [200, {"Content-Type" => 'text/plain'}, str]
  end

  get('/modify') do
    [200, {"Content-Type" => 'text/plain'}, "modified"]
  end

  get('/foo/bar', TextHandler.new("FooBar"))
  get('/foo/bar/baz0', TextHandler.new("FooBarBaz0"))
  get('/foo/bar/baz1', TextHandler.new("FooBarBaz1"))
  get('/foo/bar/baz2', TextHandler.new("FooBarBaz2"))
  get('/foo/baz', TextHandler.new("FooBaz"))
end
