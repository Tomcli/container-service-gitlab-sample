#!/bin/bash
set -x
cf install-plugin https://static-ice.ng.bluemix.net/ibm-containers-linux_x64
cf ic init
name=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 16 | head -n 1)
cf ic namespace set $name
cf ic init
cf ic login
cf ic images
cf ic build -t registry.ng.bluemix.net/<namespace>/gitlab-postgres containers/postgresql/.
cf ic build -t registry.ng.bluemix.net/<namespace>/gitlab containers/gitlab/.
cf ic cpi redis:alpine registry.ng.bluemix.net/<namespace>/redis
cf ic volume create postgresql
cf ic volume create redis
cf ic volume create gitlab
curl -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose ; chmod +x /usr/local/bin/docker-compose
cf ic run -d --name pgsql --volume postgresql:/var/lib/postgresql registry.ng.bluemix.net/<namespace>/gitlab-postgresql
cf ic run -d --name redis --volume redis:/var/lib/redis registry.ng.bluemix.net/<namespace>/redis
cf ic run -d --volume gitlab:/home/git/data --link pgsql:postgresql --link redis:redis --publish 10022:22 --publish 10080:80 gitlab
cf ic ip request
cf ic ip list
cf ic ip bind 10022:22 10080:80 
