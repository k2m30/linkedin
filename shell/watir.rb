require 'watir-webdriver'

b = Watir::Browser.new :chrome
b.goto 'linkedin.com'

b.text_fields.first.set '1m@tut.by'
b.text_fields[1].set 'hereweare'
b.buttons.first.click

b.goto 'https://www.linkedin.com/profile/view?trk=contacts-contacts-list-contact_name-0&id=109997988'
sleep 5
b.links(class: 'connections-link').first.click
sleep 5
connection_links = []
names = b.links(class: 'connections-name')
begin
until names.to_a.empty?
  p b.links(class: 'connections-name').map(&:text)
  connection_links << b.links(class: 'connections-name').map(&:href)
  if b.buttons(class: 'carousel-control-disabled').last.text == 'Next'
    b.buttons(class: 'carousel-control-disabled').last.click
  else
    break
  end
  break if connection_links.size != connection_links.uniq.size

  sleep(rand(0.9..3.2))
  names = b.links(class: 'connections-name')
end
rescue => e
  p connection_links
end

p connection_links.flatten!

connection_links.flatten!
p connection_links.size
connection_links.each { |l| b.goto l; sleep(rand(1.0..4.0)) }