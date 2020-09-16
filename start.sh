#!/bin/sh

bundle install --without development test
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake redmine:plugins:migrate
rm -rf ${APP_HOME}/tmp/pids/server.pid
rails s -b 0.0.0.0

