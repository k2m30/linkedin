require_relative 'linkedin'

server = Server.new('http://176.31.71.89:3000')
user_name = nil
invitation_limit = nil
start_url = nil

if ARGV.empty?
  users = server.users
else
  users_names = ARGV[0].gsub(' ','').split(',')
  invitation_limit = ARGV[1].to_i unless ARGV[1].nil?
  start_url = ARGV[2]
  users = server.users.select { |u| users_names.include? u[:dir]  }
end

p [users.size, user_name, invitation_limit, start_url]
users.each do |user|
  server.log(user, 'started invitation')
  crawler = Linkedin.new user, server
  crawler.third_connections = false
  crawler.wait
  url = start_url || server.get_next_url(user)
  invitation_limit ||= 500
  while crawler.invitations < invitation_limit && crawler.pages_visited < invitation_limit/4 && crawler.searches_made < 30 && url do
    url = crawler.crawl(url)
    p [user[:dir], crawler.searches_made, ' searches made and ', crawler.invitations, ' invitations sent and ', crawler.pages_visited, ' pages visited']
  end
  final_message = ['Finished ', user[:dir], ', ', crawler.searches_made, ' searches made and ', crawler.invitations, ' invitations sent and ', crawler.pages_visited, ' pages visited'].join
  p final_message
  server.log(user, final_message)
  server.pause(user)
  break unless url
  crawler.destroy
end