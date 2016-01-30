require 'csv'
require 'pp'
require 'yaml'
require 'watir'
require 'watir-webdriver'
require './user'

class Linkedin
  attr_accessor :invitations, :pages_visited

  def initialize(user)
    @base_address = 'http://176.31.71.89:3000'
    @wait_period = 0.2..2.2
    @invitations = 0
    @pages_visited = 0
    @user = user
  end

  def self.load_users(file='../../config/users/users.yml')
    users = File.open(file) { |yf| YAML::load(yf) }
    users.keys.map { |key| User.new(key, users[key]['l'], users[key]['p'],
                                    users[key]['proxy'], users[key]['dir'], users[key]['url']) }
  end

  def self.save_users(file='users.yml', users)
    hash = {}
    users.each do |user|
      hash.merge! user.to_hash
    end

    File.open(file, 'w+') do |f|
      f.puts hash.to_yaml
    end
  end

  def remove_ads
    %w(ads-col responsive-nav-scrollable bottom-ads-container).each do |id|
      begin
        @b.element(css: "##{id}").wait_until_present
        @b.execute_script("document.getElementById('#{id}').remove();")
      rescue => e
        p e.message
      end
    end
  end

  def login
    wait
    @b.text_fields.first.set @user.login
    @b.text_fields[1].set @user.password
    @b.buttons.first.click
  end

  def go_through_links(url)
    person_selector = '.people.result'
    minus_words = %w(marketing sales soft hr recruitment assistant development coach)
    @b.elements(css: person_selector).to_a.each_index do |i|
      item = @b.elements(css: person_selector)[i]
      name = item.element(css: '.main-headline')
      position = item.element(css: '.bd .description')
      industry = item.element(css: '.separator~ dd')
      location = item.element(css: '#results bdi')

      name = name.exist? ? name.text : ''
      position = position.exist? ? position.text : ''
      industry = industry.exist? ? industry.text : ''
      location = location.exist? ? location.text : ''

      begin
        linkedin_id = URI(item.a(css: 'a.primary-action-button.label').href).query.split('&').select { |a| a.include?('key=') }.first.gsub('key=', '').to_i
      rescue
        linkedin_id = nil
      end

      person = {name: name, position: position, industry: industry, location: location, linkedin_id: linkedin_id, owner: @user.dir}

      uri = URI("#{@base_address}/person")
      uri.query = URI.encode_www_form person
      user_exist = Net::HTTP.get(uri) == 'true'

      p uri.query
      unless user_exist
        next if minus_words.map { |a| position.downcase.include? a }.include? true
        # button = item.element(css: 'a.primary-action-button')
        button = item.element(text: 'Connect')
        if button.exist?
          button.click
          wait

          if @b.url == url
            @invitations += 1
          else
            wait
            @b.goto url
          end
        end
      end
    end
  end

  def wait_page_for_load
    active_link_selector = 'li.active'
    @b.element(css: '#results-pagination').wait_until_present
    Watir::Wait.until { @b.element(css: active_link_selector).exist? }
  end

  def wait
    sleep(rand(@wait_period))
  end

  def open_browser
    # prefs = {profile: {managed_default_content_settings: {images: 2}}}
    prefs = {}
    switches = %W[--user-data-dir=#{ENV['HOME']}/1chrm/#{@user.dir} --proxy-server=#{@user.proxy}]
    @b = Watir::Browser.new :chrome, switches: switches, prefs: prefs
    @b.goto 'linkedin.com'

    login if @b.text.include?('Forgot password?')
    wait
  end

  def crawl(url)
    open_browser if @b.nil?
    @b.goto url
    wait

    search_result_selector = '.search-info p strong'

    if @b.element(css: search_result_selector).text.gsub(',', '').to_i <= 10
      p ['not enough search results', @b.element(css: search_result_selector).text, url]
      return @user.get_next_url
    end

    remove_ads

    begin
      if @b.text.include? 'Sorry, no results containing all your search terms were found'
        # @b.close
        return @user.get_next_url
      end

      url = @b.url

      wait_page_for_load
      go_through_links(url)
      wait
      @pages_visited += 1

      if @b.text.include?('Next >')
        @b.element(text: 'Next >').click
      else
        # byebug
        # @b.close
        return @user.get_next_url
      end

    rescue => e
      p e.message
      pp e.backtrace[0..4]
      url = @b.url
      # byebug
      unless @b.text.include?('Security Verification') #wait for captcha
        # @b.close
        return url
      end
    end while @b.text.include?('Next >')

    false
  end

  def destroy
    @b.close
  end
end

users = Linkedin.load_users


users.each do |user|
  crawler = Linkedin.new user
  crawler.wait
  url = user.get_next_url
  while crawler.invitations < 1000 && crawler.pages_visited < 250 && url do
    url = crawler.crawl(url)
    p [user.dir, crawler.invitations, 'invitations sent and ', crawler.pages_visited, ' pages visited']
  end
  p ['Finished', user.dir, crawler.invitations, 'invitations sent and ', crawler.pages_visited, ' pages visited']
  crawler.destroy
end