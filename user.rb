class User
  attr_accessor :id, :login, :password, :proxy, :url

  def initialize(id, login ,password, proxy, url)
    @id = id
    @login = login
    @password = password
    @proxy = proxy
    @url = url
  end

  def to_hash
    {@id => {'l' => @login, 'p' => @password, 'proxy'=> @proxy, 'url' => @url}}
  end
end