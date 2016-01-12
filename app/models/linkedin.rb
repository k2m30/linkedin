class Linkedin
  require 'csv'
  require 'pp'
  require 'yaml'
  require 'watir'
  require 'watir-webdriver'

  @base_address = 'http://176.31.71.89:3000'

  def self.load_users(file='./config/users.yml')
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

  def self.crawl(url, user)

    prefs = {profile: {managed_default_content_settings: {images: 2}}}
    switches = %W[--user-data-dir=#{ENV['HOME']}/1chrm/#{user.dir} --proxy-server=#{user.proxy}]
    b = Watir::Browser.new :chrome, switches: switches, prefs: prefs

    b.goto 'linkedin.com'
    if b.text.include?('Forgot password?')
      sleep 5
      b.text_fields.first.set user.login
      b.text_fields[1].set user.password
      b.buttons.first.click
    end
    sleep 5
    b.goto url

    invitations = 0
    minus_words = %w(marketing sales soft hr recruitment assistant)
    wait_period = 0.2..2.2
    active_link_selector = 'li.active'
    next_page_link_selector = 'li.next>a.page-link'
    person_selector = '.people.result'

    page = b.element(css: active_link_selector).text.to_i

    begin
      while b.element(css: next_page_link_selector).exists?
        url = b.url
        p 'waiting'
        p url
        b.element(css: active_link_selector).wait_until_present
        Watir::Wait.until { b.element(css: active_link_selector).exist? && b.element(css: active_link_selector).text == page.to_s && b.elements(css: '.main-headline').to_a.size == 10 }
        p [b.element(css: active_link_selector).text, page]
        b.elements(css: person_selector).to_a.each_index do |i|

          item = b.elements(css: person_selector)[i]
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
          user_exist = Net::HTTP.get(uri) == 'true'

          p [person[:name], user_exist]
          unless user_exist
            next if minus_words.map { |a| position.downcase.include? a }.include? true
            button = item.element(css: 'a.primary-action-button')
            button.click
            # p person
            sleep(rand(wait_period))

            succeed = b.url == url

            if succeed
              invitations += 1
            else
              sleep(rand(wait_period))
              b.goto url
            end
          end
        end

        sleep(rand(wait_period))
        page = page + 1
        if b.text.include?('Next >')
          Watir::Wait.until { b.element(css: next_page_link_selector).exist? }
          b.element(css: next_page_link_selector).click
        else
          return user.get_next_url(url), invitations
        end
      end
    rescue => e
      p e.message
      pp e.backtrace[0..4]
      url = b.url
      unless b.text.include?('Security Verification') #wait for captcha
        b.close
        return url, invitations
      end
    end

    false
  end

  def self.start
    users = load_users

    threads = []
    initial_size = Net::HTTP.get(URI("#{@base_address}/count"))
    p ['initial size', initial_size]

    users.each do |user|
      threads << Thread.new do
        sleep(rand(0.1..3.2))
        url = user.url
        invitations = 0
        10.times do
          if url
            url, i = crawl(url, user)
            invitations += i
            if invitations > 1000
              p [user.dir, invitations, 'invitations sent']
              break
            end
            user.url = url
          end
        end
      end
    end

    threads.each do |thread|
      thread.join
    end

    final_size = Net::HTTP.get(URI("#{@base_address}/count"))
    p ['final size', final_size]
    p "#{final_size.to_i-initial_size.to_i} invitations sent"
  end
end