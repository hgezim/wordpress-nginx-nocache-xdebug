#!/bin/bash

if [ ! -d /usr/share/nginx/html/wordpress ]; then
    mkdir /usr/share/nginx/html/wordpress/
fi
# copy WP files
cp -r /usr/share/nginx/wp_tmp/* /usr/share/nginx/html/wordpress/
supervisord -c /etc/supervisor/supervisord.conf