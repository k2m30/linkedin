require_relative 'linkedin'

server = Server.new('http://176.31.71.89:3000')
user_name = nil
messages_limit = nil
start_url = nil
if ARGV.empty?
  users = server.users
else
  users_names = ARGV[0].gsub(' ', '').split(',')
  messages_limit = ARGV[1].to_i unless ARGV[1].nil?
  users = server.users.select { |u| users_names.include? u[:dir] }
end
p [users.size, user_name, messages_limit, start_url]
users.each do |user|
  mailer = Linkedin.new user, server
  mailer.wait
  mailer.send_mails
  mailer.destroy
end