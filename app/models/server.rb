require 'json'

class Server
  attr_accessor :base_address

  class NoUrlException < StandardError; end

  def initialize(base_address = 'http://176.31.71.89:3000')
    @base_address = base_address
  end


  def users
    uri = URI("#{@base_address}/users.json")
    JSON.parse Net::HTTP.get(uri), symbolize_names: true
  end

  def get_next_url(user)
    id = {id: user[:id]}
    uri = URI("#{@base_address}/next_url")
    uri.query = URI.encode_www_form id
    url = Net::HTTP.get(uri)

    raise NoUrlException.new('No search url found') if url == 'false'
    url
  end

  def person_exists?(person)
    uri = URI("#{@base_address}/person")
    uri.query = URI.encode_www_form person
    Net::HTTP.get(uri) == 'true'
  end
end