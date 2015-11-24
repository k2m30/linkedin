require 'csv'
require 'pp'
require 'watir'
require 'watir-webdriver'

def load_base(file = './2ndconnections.csv')
  return CSV.read(file)
end

def add_item_to_base(file = './2ndconnections.csv', person)
  CSV.open(file, "a") do |csv|
    csv << person
  end
end

def merge_bases(file1 = './2ndconnections.csv', file2 = './2ndconnections_alex.csv')
  base1 = load_base file1
  base2 = load_base file2

  items_to_add = base2 - base1

  items_to_add.each { |item| add_item_to_base file1, item }
end

# switches = ['--proxy-server=88.12.44.205:3128']

def crawl(url)

  prefs = {:profile => {:managed_default_content_settings => {:images => 2}}}
  b = Watir::Browser.new :chrome, :prefs => prefs
  b.goto 'linkedin.com'

  b.text_fields.first.set '1m@tut.by'
  b.text_fields[1].set 'hereweare'
  b.buttons.first.click

  b.goto url
  sleep 5

  base = load_base
  active_link_selector = 'li.active'
  next_page_link_selector = 'li.next>a.page-link'

  page = b.element(css: active_link_selector).text.to_i

  begin
    while b.element(css: next_page_link_selector).exists?
      url = b.url
      p 'waiting'
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

        person = [name, position, industry, location]
        p person
        unless base.include? person
          button = item.element(css: '.primary-action-button')
          button.click
          sleep(rand(0.9..3.2))

          succeed = b.url == url
          add_item_to_base(person)

          unless succeed
            sleep(rand(0.9..3.2))
            b.goto url
            base = load_base
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
    return url
  end

  false
end


url = 'https://www.linkedin.com/vsearch/p?title=managing%20director&openAdvancedForm=true&titleScope=CP&locationType=I&countryCode=gb&f_CS=4&rsid=4120029691448361298875&orig=FCTD&pt=people&f_G=gb%3A0&f_L=en&f_N=S&openFacets=N,G,CC,I,L,CS'

10.times do
  url = crawl(url)
end

