require 'json'

class Server
  attr_accessor :base_address

  class NoUrlException < StandardError; end
  class PersonErrorException < StandardError; end
  class UrlErrorException < StandardError; end

  def initialize(base_address = 'http://127.0.0.1:3000')
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
    raise UrlErrorException.new(url) unless url.include? 'https://www.linkedin.com/vsearch/p?'
    url
  end

  def person_exists?(person)
    uri = URI("#{@base_address}/person")
    uri.query = URI.encode_www_form person
    response = Net::HTTP.get(uri)
    raise PersonErrorException.new(response) unless %w(true false).any? {|o| o.include? response}
    response == 'true'
  end
end