require 'csv'
require 'pp'
require 'yaml'
require 'open-uri'
require 'net/http'
require 'watir'
require 'watir-webdriver'
require_relative 'server'
require 'logger'

class Linkedin
  attr_accessor :invitations, :pages_visited, :searches_made, :b

  def initialize(user, server)
    @wait_period = 1.2..3.2
    @invitations = 0
    @pages_visited = 0
    @searches_made = 0
    @user = user
    @server = server
    @logger = Logger.new('log/linkedin.log')
  end

  def login_ok?
    text = @b.text
    text.include?('Business Services') || text.include?('Save search')
  end

  def search_ok?
    text = @b.text
    if text.include? 'Due to excessive searching, your people search results are limited'
      p 'Due to excessive searching, your people search results are limited to your 1st-degree connections for security reasons. This restriction will be lifted in 24 hours.'
      return false
    end

    if text.include? 'We have detected an unusually high number of page views from your account'
      p 'We have detected an unusually high number of page views from your account. This may indicate that your account is being used for unauthorized activities that violate LinkedIn\'s User Agreement [see section 8.2] and the privacy of our members.'
      return false
    end
    if text.include? 'reached the commercial use limit on search'
      p 'You’ve reached the commercial use limit on search.'
      return false
    end
    true
  end

  def enough_search_results?
    search_result_selector = '.search-info p strong'
    if @b.element(css: search_result_selector).text.gsub(',', '').to_i <= 10
      p ['not enough search results', @b.element(css: search_result_selector).text, @b.url]
      return false
    end
    if @b.text.include? 'Sorry, no results containing all your search terms were found'
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

    return false unless search_ok?
    return @server.get_next_url(@user) unless enough_search_results?

    remove_ads

    begin
      url = @b.url

      wait_page_for_load
      return false unless go_through_links(url)
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
      p e
      p e.message
      pp e.backtrace[0..4].select{|m| m.include? Dir.pwd}
      url = @b.url
      unless @b.text.include?('Security Verification') #wait for captcha
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
    # wait
    %w(ads-col responsive-nav-scrollable bottom-ads-container member-ads).each do |id|
      begin
        @b.execute_script("ad = document.getElementById('#{id}');if(!(ad==null)){ad.remove();}")
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
    return false unless search_ok?
    @b.elements(css: person_selector).to_a.each_index do |i|
      begin
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
          person_link = URI(item.a(css: 'a.primary-action-button.label').href)
          linkedin_id = person_link.query.split('&').select { |a| a.include?('key=') }.first.gsub('key=', '').to_i
        rescue => e
          process_exception("No linkedin_id: #{item.html}",e)
          next
        end

        person = {name: name, position: position, industry: industry, location: location, linkedin_id: linkedin_id, owner: @user[:dir]}

        unless @server.person_exists?(person)
          next if minus_words.map { |a| position.downcase.include? a }.include? true
          # button = item.element(css: 'a.primary-action-button')
          button = item.element(text: 'Connect')
          if button.exist?
            button.click if @server.remote?
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
      rescue Selenium::WebDriver::Error::UnknownError => e
        process_exception('Selemium',e)
      rescue Watir::Exception::UnknownObjectException => e
        process_exception('Watir', e)
      end
    end
  end

  def process_exception(message, e)
    @logger.error e.message
    trace = e.backtrace[0..4].select{|m| m.include? Dir.pwd}
    trace.insert 0, message
    @logger.error trace unless trace.empty?
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


server = Server.new('http://176.31.71.89:3000')
user_name = nil
invitation_limit = nil
start_url = nil
if ARGV.empty?
  users = server.users
else
  user_name = ARGV[0]
  invitation_limit = ARGV[1].to_i
  start_url = ARGV[2]
  users = server.users.select { |u| u[:dir] == user_name }
end

p [users.size, user_name, invitation_limit, start_url]
users.each do |user|
  crawler = Linkedin.new user, server
  crawler.wait
  url = start_url || server.get_next_url(user)
  invitation_limit || 350
  while crawler.invitations < invitation_limit && crawler.pages_visited < invitation_limit/4 && crawler.searches_made < 30 && url do
    url = crawler.crawl(url)
    p [user[:dir], crawler.searches_made, ' searches made and ', crawler.invitations, ' invitations sent and ', crawler.pages_visited, ' pages visited']
  end
  p ['Finished', user[:dir], crawler.searches_made, ' searches made and ', crawler.invitations, 'invitations sent and ', crawler.pages_visited, ' pages visited']
  break unless url
  crawler.destroy
end