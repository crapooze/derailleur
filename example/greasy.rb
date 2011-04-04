
$LOAD_PATH << 'lib'

require 'derailleur/base/grease'

class MyApplication
  include Derailleur::Grease

  get('/') do
    "hello world"
  end

  get('/hello/:who') do
    ret = "hello #{params[':who']}"
    ret << " with extension: #{extname}" unless extname.empty?
    ret
  end

  get('/lost') do
    @status = 404
    "not found"
  end
end

ExampleApplication = MyApplication.new
