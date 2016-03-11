require_relative 'linkedin'

server = Server.new('http://176.31.71.89:3000')
user_name = nil
messages_limit = nil
start_url = nil
if ARGV.empty?
  users = server.users
else
  user_name = ARGV[0]
  messages_limit = ARGV[1].to_i
  start_url = ARGV[2]
  users = server.users.select { |u| u[:dir] == user_name }
end

p [users.size, user_name, messages_limit, start_url]
users.each do |user|
  mailer = Linkedin.new user, server
  mailer.wait
  mailer.send_mails
  mailer.destroy
  break
end