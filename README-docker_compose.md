# Starting dev environment

Start services:

sudo docker-compose up

Enter image:

# What is going on

gdk is gem, gdk install -> executes make

postgres:
make:
  * calls initdb shell command (not necessary)
  * support/bootstrap-rails


support/bootstrap-rails -> gitlab dir -> bundle exec rake db:create