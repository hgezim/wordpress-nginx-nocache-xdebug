#!/bin/bash

set -x

if [ ! -d /usr/share/nginx/html/wordpress ]; then
    mkdir /usr/share/nginx/html/wordpress/
fi
# copy WP files
cp -r /usr/share/nginx/wp_tmp/* /usr/share/nginx/html/wordpress/

# We need the host machine name or IP for Xdebug to work
# On windows and mac host.docker.internal resolves to host IP but
# on linux we have to use the default gateway
# So, we first try to use host.docker.internal and if that fails to resolve we fallback on the default gateway
ping -c 1 host.docker.internal
if [ $? -eq 0 ]
then
	HOST_IP='host.docker.internal'
else
	HOST_IP=$(ip -4 route list match 0/0 | cut -d' ' -f3)
fi

export XDEBUG_CONFIG="remote_host=${HOST_IP} remote_log=/var/log/xdebug_remote.log"
supervisord -c /etc/supervisor/supervisord.conf
