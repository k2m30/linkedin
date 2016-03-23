require 'mina/bundler'
# require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '176.31.71.89'
set :deploy_to, '/home/deployer/mina'
set :repository, 'http://github.com/k2m30/linkedin'
set :branch, 'master'
set :rvm_path, '/home/deployer/.rvm/bin/rvm'

  set :user, 'deployer'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
  set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  invoke :'rvm:use[ruby-2.2.1@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  # queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  # queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]
  #
  # queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  # queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]
  #
  # queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  # queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  # queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

  if repository
    repo_host = repository.split(%r{@|://}).last.split(%r{:|\/}).first
    repo_port = /:([0-9]+)/.match(repository) && /:([0-9]+)/.match(repository)[1] || '22'

    queue %[
      if ! ssh-keygen -H  -F #{repo_host} &>/dev/null; then
        ssh-keyscan -t rsa -p #{repo_port} -H #{repo_host} >> ~/.ssh/known_hosts
      fi
    ]
  end
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    # invoke :'git:clone'
    # invoke :'deploy:link_shared_paths'
    # invoke :'bundle:install'
    # queue 'rake db:migrate'
    # queue 'rake assets:precompile'
    # invoke :'deploy:cleanup'

    # to :launch do
    #   queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
    #   queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    # end
  end
  to :after_hook do
    # invoke :'git:clone'
    queue 'bundle install'
    queue 'rake db:migrate'
    queue 'rake assets:precompile'
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
