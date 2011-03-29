
$LOAD_PATH << 'lib'

require 'derailleur'

module ExampleApplication
  extend Derailleur::Application::RackApplication

  @@index = 0

  def current_path
    "/#{@@index}"
  end

  def unget_current
    unget current_path
  end

  def get_next
    @@index += 1
    get(current_path) do
      unget_current
      get_next
      [200, {}, "<a href=\"/#{@@index}\">#{@@index}</a>"]
    end
  end

  extend self

  get('/') do
    get_next
    [200, {}, "<a href=\"/1\">1</a>"]
  end
end

