require 'csv'
require 'nokogiri'
require 'watir-webdriver'

b = Watir::Browser.new :chrome
b.goto 'linkedin.com'

b.text_fields.first.set '1m@tut.by'
b.text_fields[1].set 'hereweare'
b.buttons.first.click

b.goto 'https://www.linkedin.com/vsearch/p?pivotType=cofc&pid=412002969&rsid=4120029691447669021509&openFacets=N,G,CC&orig=FCTD&f_G=gb%3A0&f_N=F'
sleep 5

html = Nokogiri::HTML(b.html)
links_to_connections = html.css('div.secondary-actions-trigger ul li').children.select{|li| li.text=='View Connections'}.map{|li| li[:href]}

p links_to_connections

links_to_connections.each do |link|
  link = 'https://www.linkedin.com/' + link + '&orig=FCTD&f_G=gb%3A0' # UK only
  b.goto link
  begin
    names = b.elements(css: '.main-headline').map(&:text)
    positions = b.elements(css: '.bd .description').map(&:text)
    locations = b.elements(css: '.separator bdi').map(&:text)                    
    industries = b.elements(css: '.separator~ dd').map(&:text)
    
    CSV.open("./base.csv", "a") do |csv|
      names.each_index do |i|
        row = [names[i], positions[i], locations[i], industries[i]]
        p row
        csv << row
      end
    end
    sleep(rand(0.9..3.2))    
    b.goto b.link(text: 'Next >').href + '&orig=FCTD&f_G=gb%3A0'
  end while b.link(text: 'Next >').exists?    
end
