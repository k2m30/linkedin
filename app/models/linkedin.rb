require 'csv'
require 'pp'
require 'yaml'
require 'open-uri'
require 'net/http'
require 'watir'
require 'watir-webdriver'
require_relative 'server'

class Linkedin
  attr_accessor :invitations, :pages_visited, :searches_made

  def initialize(user, server)
    @wait_period = 0.2..2.2
    @invitations = 0
    @pages_visited = 0
    @searches_made = 0
    @user = user
    @server = server
  end

  def login_ok?
    @b.text.include?('Business Services')
  end

  def search_ok?
    if @b.text.include? 'Due to excessive searching, your people search results are limited'
      p 'Due to excessive searching, your people search results are limited to your 1st-degree connections for security reasons. This restriction will be lifted in 24 hours.'
      return false
    end

    if @b.text.include? 'We have detected an unusually high number of page views from your account'
      p 'We have detected an unusually high number of page views from your account. This may indicate that your account is being used for unauthorized activities that violate LinkedIn\'s User Agreement [see section 8.2] and the privacy of our members.'
      return false
    end
    true
  end

  def crawl(url)
    open_browser if @b.nil?
    return false unless login_ok?
    @b.goto url
    wait

    @searches_made += 1
    @pages_visited += 1

    search_result_selector = '.search-info p strong'

    return false unless search_ok?

    remove_ads

    begin
      if @b.text.include? 'Sorry, no results containing all your search terms were found'
        # @b.close
        return @server.get_next_url(@user)
      end

      if @b.element(css: search_result_selector).text.gsub(',', '').to_i <= 10
        p ['not enough search results', @b.element(css: search_result_selector).text, url]
        return @server.get_next_url(@user)
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
        return @server.get_next_url(@user)
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

  def wait
    sleep(rand(@wait_period))
  end

  def destroy
    @b.close
  end

  protected

  def remove_ads
    wait
    %w(ads-col responsive-nav-scrollable bottom-ads-container member-ads).each do |id|
      begin
        @b.execute_script("ad = document.getElementById('#{id}');if(!ad==null){ad.remove();}")
      rescue => e
        p e.message
      end
    end
  end

  def login
    wait
    @b.text_fields.first.set @user[:login]
    @b.text_fields[1].set @user[:password]
    @b.buttons.first.click
  end

  def go_through_links(url)
    person_selector = '.people.result'
    minus_words = %w(marketing sales soft hr assistant development coach recruit)
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

      person = {name: name, position: position, industry: industry, location: location, linkedin_id: linkedin_id, owner: @user[:dir]}

      unless @server.person_exists?(person)
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
            remove_ads
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

  def open_browser
    # prefs = {profile: {managed_default_content_settings: {images: 2}}}
    prefs = {}
    switches = %W[--user-data-dir=#{ENV['HOME']}/1chrm/#{@user[:dir]} --proxy-server=#{@user[:proxy]}]
    @b = Watir::Browser.new :chrome, switches: switches, prefs: prefs
    @b.goto 'linkedin.com'

    login if @b.text.include?('Forgot password?')
    wait
  end
end

# users = User.load_users

server = Server.new('http://127.0.0.1:3000')

if ARGV.empty?
  users = server.users
else
  users = server.users.select { |u| u[:dir]==ARGV[0] }
end

users.each do |user|
  crawler = Linkedin.new user, server
  crawler.wait
  url = server.get_next_url(user)
  while crawler.invitations < 350 && crawler.pages_visited < 80 && crawler.searches_made < 30 && url do
    url = crawler.crawl(url)
    p [user[:dir], crawler.searches_made, ' searches made and ', crawler.invitations, ' invitations sent and ', crawler.pages_visited, ' pages visited']
  end
  p ['Finished', user[:dir], crawler.searches_made, ' searches made and ',crawler.invitations, 'invitations sent and ', crawler.pages_visited, ' pages visited']
  break unless url
  crawler.destroy
end