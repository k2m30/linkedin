require 'csv'
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
  
  items_to_add.each {|item| add_item_to_base file1, item}
end

b = Watir::Browser.new :chrome
b.goto 'linkedin.com'

b.text_fields.first.set '1m@tut.by'
b.text_fields[1].set 'hereweare'
b.buttons.first.click

# b.goto 'https://www.linkedin.com/vsearch/p?title=CEO&openAdvancedForm=true&titleScope=CP&locationType=I&countryCode=gb&f_N=S&f_CS=2,3&rsid=4120029691447840224428&orig=MDYS'
b.goto 'https://www.linkedin.com/vsearch/p?title=managing%20director&openAdvancedForm=true&titleScope=CP&locationType=I&countryCode=gb&f_CS=3&rsid=4120029691448025268989&orig=FCTD&f_I=43,96&page_num=61&pt=people&f_N=S&openFacets=N,G,CC,I,CS'
sleep 5

base = load_base
page = b.element(css: '.active').text.to_i
while b.element(css: '.next .page-link').exists?
  break if page > 100
  url = b.url
  p 'waiting'
  Watir::Wait.until {   b.element(css: '.active').exist? && b.element(css: '.active').text == page.to_s && b.elements(css: '.main-headline').to_a.size == 10 }
  p [b.element(css: '.active').text, page]
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
  b.element(css: '.next .page-link').click
  
end 