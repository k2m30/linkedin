class User < ActiveRecord::Base
  class NoUrlException < StandardError; end

  # attr_accessor :id, :login, :password, :proxy, :url, :dir, :industry

  # def initialize(id='name', login='hilton.joel@yahoo.com', password='Razdvatri!23123', proxy='', dir='Joel_Hilton', url='', industry = 43)
  #   @id = id
  #   @login = login
  #   @password = password
  #   @proxy = proxy
  #   @url = url
  #   @dir = dir
  #   @industry = industry
  # end

  def self.load_users(file='../../config/users/users.yml')
    users = File.open(file) { |yf| YAML::load(yf) }
    users.keys.map { |key| User.create(login: users[key]['l'], password: users[key]['p'],
                                    proxy: users[key]['proxy'], dir: users[key]['dir'], industry: users[key]['industry'],
                                    command_str: "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --enable-udd-profiles --user-data-dir=#{ENV['HOME']}/1chrm/#{users[key]['dir']}") }
  end

  # def to_hash
  #   {@id => {'l' => @login, 'p' => @password, 'proxy' => @proxy, 'dir' => @dir, 'url' => @url, 'industry' => @industry}}
  # end

  def get_next_url(base_address)
    person = {owner: dir, industry: industry}
    uri = URI("#{base_address}/next_url")
    uri.query = URI.encode_www_form person
    url = Net::HTTP.get(uri)

    raise NoUrlException.new('No search url found') if url == 'false'
    url
  end
end