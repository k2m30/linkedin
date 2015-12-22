class Linkedin
  require 'csv'
  require 'pp'
  require 'yaml'
  require 'watir'
  require 'watir-webdriver'

  @base_address = 'http://176.31.71.89:3000'

  def self.load_users(file='./config/users.yml')
    users = File.open(file) { |yf| YAML::load(yf) }
    users.keys.map { |key| User.new(key, users[key]['l'], users[key]['p'], users[key]['proxy'], users[key]['url']) }
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

  def self.crawl(url, user)

    prefs = {profile: {managed_default_content_settings: {images: 2}}}
    switches = ["--proxy-server=#{user.proxy}"]
    b = Watir::Browser.new :chrome, prefs: prefs, switches: switches
    b.goto 'linkedin.com'

    b.text_fields.first.set user.login
    b.text_fields[1].set user.password
    b.buttons.first.click

    b.goto url
    sleep 5

    p ['initial size', Net::HTTP.get(URI("#{@base_address}/count"))]
    minus_words = %w(marketing sales soft hr recruitment assistant)

    active_link_selector = 'li.active'
    next_page_link_selector = 'li.next>a.page-link'

    page = b.element(css: active_link_selector).text.to_i

    begin
      while b.element(css: next_page_link_selector).exists?
        url = b.url
        p 'waiting'
        p url
        b.element(css: active_link_selector).wait_until_present
        Watir::Wait.until { b.element(css: active_link_selector).exist? && b.element(css: active_link_selector).text == page.to_s && b.elements(css: '.main-headline').to_a.size == 10 }
        p [b.element(css: active_link_selector).text, page]
        b.elements(css: '.result').to_a.each_index do |i|

          item = b.elements(css: '.result')[i]
          name = item.element(css: '.main-headline')
          position = item.element(css: '.bd .description')
          industry = item.element(css: '.separator~ dd')
          location = item.element(css: '#results bdi')

          name = name.exist? ? name.text : ''
          position = position.exist? ? position.text : ''
          industry = industry.exist? ? industry.text : ''
          location = location.exist? ? location.text : ''

          begin
            linkedin_id = URI(item.as(css: 'a.primary-action-button.label').first.href).query.split('&').select { |a| a.include?('key=') }.first.gsub('key=', '').to_i
          rescue => e
            p e.message
            pp e.backtrace[0..4]
            linkedin_id = nil
          end

          person = {name: name, position: position, industry: industry, location: location, linkedin_id: linkedin_id}


          uri = URI("#{@base_address}/person")
          uri.query = URI.encode_www_form person
          result = Net::HTTP.get(uri) == 'true'

          p [person[:name], result]
          unless result
            next if minus_words.map{|a| position.downcase.include? a}.include? true
            button = item.element(css: '.primary-action-button')
            button.click
            # p person
            sleep(rand(0.9..3.2))

            succeed = b.url == url

            unless succeed
              sleep(rand(0.9..3.2))
              b.goto url
            end
          end
        end

        sleep(rand(0.9..3.2))
        page = page + 1
        Watir::Wait.until { b.element(css: next_page_link_selector).exist? }
        b.element(css: next_page_link_selector).click
      end
    rescue => e
      p e.message
      pp e.backtrace[0..4]
      url = b.url
      b.close
      return false if page == 100
      return url
    end

    false
  end

  def self.start
    users = load_users

    threads = []

    users.each do |user|
      threads << Thread.new do
        url = user.url
        10.times do
          if url
            url = crawl(url, user)
            user.url = url
          end
        end
      end
    end

    threads.each do |thread|
      thread.join
    end

    p ['final size', Net::HTTP.get(URI("#{@base_address}/count"))]
  end
end