class User
  class NoUrlException < StandardError; end

  attr_accessor :id, :login, :password, :proxy, :url, :dir, :industry

  def initialize(id='name', login='hilton.joel@yahoo.com', password='Razdvatri!23123', proxy='', dir='Joel_Hilton', url='', industry = 43)
    @id = id
    @login = login
    @password = password
    @proxy = proxy
    @url = url
    @dir = dir
    @industry = industry
  end

  def self.load_users(file='../../config/users/users.yml')
    users = File.open(file) { |yf| YAML::load(yf) }
    users.keys.map { |key| User.new(key, users[key]['l'], users[key]['p'],
                                    users[key]['proxy'], users[key]['dir'], users[key]['url']) }
  end

  def to_hash
    {@id => {'l' => @login, 'p' => @password, 'proxy' => @proxy, 'dir' => @dir, 'url' => @url, 'industry' => @industry}}
  end

  def get_next_url(base_address)
    person = {owner: @dir, industry: @industry}
    uri = URI("#{base_address}/next_url")
    uri.query = URI.encode_www_form person
    url = Net::HTTP.get(uri)

    raise NoUrlException.new('No search url found') if url == 'false'
    url
  end
end