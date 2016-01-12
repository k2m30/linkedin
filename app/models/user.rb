class User
  attr_accessor :id, :login, :password, :proxy, :url, :dir

  def initialize(id, login ,password, proxy, dir, url)
    @id = id
    @login = login
    @password = password
    @proxy = proxy
    @url = url
    @dir = dir
  end

  def to_hash
    {@id => {'l' => @login, 'p' => @password, 'proxy'=> @proxy, 'dir' =>@dir, 'url' => @url}}
  end
end