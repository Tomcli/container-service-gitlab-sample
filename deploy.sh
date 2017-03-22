#!/bin/bash
set -x
cf add-plugin-repo bluemix http://plugins.ng.bluemix.net/
cf install-plugin IBM-Containers -r Bluemix
cf ic init
name=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 16 | head -n 1)
cf ic namespace set $name
name=$(cf ic namespace get)
cf ic init
cf ic login
cf ic images
cd containers/postgres
cf ic build -t registry.ng.bluemix.net/$name/gitlab-postgres .
cd ..
cd gitlab
cf ic build -t registry.ng.bluemix.net/$name/gitlab .
cd ..
cd ..
cf ic cpi redis:alpine registry.ng.bluemix.net/$name/redis
cf ic volume create postgresql
cf ic volume create redis
cf ic volume create gitlab
curl -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose ; chmod +x /usr/local/bin/docker-compose
sleep 3m
cf ic run -d --name pgsql --volume postgresql:/var/lib/postgresql registry.ng.bluemix.net/$name/gitlab-postgresql
cf ic run -d --name redis --volume redis:/var/lib/redis registry.ng.bluemix.net/$name/redis
cf ic run -d --volume gitlab:/home/git/data --link pgsql:postgresql --link redis:redis --publish 10022:22 --publish 10080:80 gitlab
cf ic ip request
cf ic ip list
ip=$(cf ic ip list | grep -v "Number" | grep -v "Listing" | grep -v "IP")
cf ic ip bind $ip
