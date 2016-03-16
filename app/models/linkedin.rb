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
  attr_accessor :invitations, :pages_visited, :searches_made, :b, :third_connections
  class AlarmException < StandardError;
  end

  def initialize(user, server)
    @wait_period = 1.2..3.2
    @invitations = 0
    @pages_visited = 0
    @searches_made = 0
    @user = user
    @server = server
    @logger =
        begin
          Logger.new('log/linkedin.log')
        rescue
          Logger.new('../../log/linkedin.log')
        end
  end

  def login_ok?
    text = @b.text
    text.include?('Business Services') || text.include?('Save search')
  end

  def search_ok?
    text = @b.text
    if text.include? 'Due to excessive searching, your people search results are limited'
      message = 'Due to excessive searching, your people search results are limited to your 1st-degree connections for security reasons. This restriction will be lifted in 24 hours.'
      p message
      @server.log(@user, message)
      return false
    end

    if text.include? 'We have detected an unusually high number of page views from your account'
      message = 'We have detected an unusually high number of page views from your account. This may indicate that your account is being used for unauthorized activities that violate LinkedIn\'s User Agreement [see section 8.2] and the privacy of our members.'
      p message
      @server.log(@user, message)
      return false
    end
    if text.include? 'reached the commercial use limit on search'
      message = 'You’ve reached the commercial use limit on search.'
      p message
      @server.log(@user, message)
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

  def send_mails
    @server.log(@user, 'Messaging started')
    open_browser if @b.nil?
    return false unless login_ok?

    messaging_hash = load_messages("../../config/users/#{@user[:dir]}.csv") #{:'461658896' => 'Hi there', :'412002969' => "Hello, Michael\nHow are you?"}

    messaging_hash.each do |row|
      send_message(row['linkedin_id'], row['Msg1 text'] || row['linkedin msg1'])
      p row['linkedin_id']
      wait
    end
    @server.log(@user, "#{messaging_hash.size} messages sent")
  end

  def load_messages(filename='../../config/users/Alex_Ye.csv')
    CSV.parse(File.read(filename), headers: true).by_row!
  end

  def send_message(id, message)
    @b.goto "https://www.linkedin.com/messaging/compose?connId=#{id}"
    if @b.alert.exists?
      wait
      @b.alert.ok
    end
    wait
    @b.checkbox(css: 'input#enter-to-send-checkbox').set false
    wait
    form = @b.textarea(css: 'textarea#compose-message')
    form.set message
    wait
    send_btn = @b.button(css: '.message-submit')
    send_btn.click if send_btn.exists?
  end

  def crawl(url)
    open_browser if @b.nil?
    return false unless login_ok?
    @b.goto url
    wait

    @searches_made += 1
    @pages_visited += 1

    return false unless login_ok?
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
        raise AlarmException if @b.url == url
      else
        return @server.get_next_url(@user)
      end

    rescue => e
      p e
      p e.message
      pp e.backtrace[0..4].select { |m| m.include? Dir.pwd }
      url = @b.url
      unless security_verification?
        return url
      end
    end while @b.text.include?('Next >')

    false
  end

  def security_verification?
    @b.text.include?('Security Verification') || @b.text.include?('Action required')
  end

  def wait
    sleep(rand(@wait_period))
  end

  def destroy
    @b.close unless @b.nil?
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
    minus_words = %w(marketing sales soft hr assistant development coach recruit consultant)
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
          process_exception("No linkedin_id: #{item.html}", e)
          next
        end

        person = {name: name, position: position, industry: industry, location: location, linkedin_id: linkedin_id, owner: @user[:dir]}
        next if minus_words.map { |a| position.downcase.include? a }.include? true

        unless @server.person_exists?(person)
          if @server.remote? and not @third_connections
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
      rescue Selenium::WebDriver::Error::UnknownError => e
        process_exception('Selemium', e)
      rescue Watir::Exception::UnknownObjectException => e
        process_exception('Watir', e)
      end
    end
  end

  def process_exception(message, e)
    @logger.error e.message
    trace = e.backtrace[0..4].select { |m| m.include? Dir.pwd }
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