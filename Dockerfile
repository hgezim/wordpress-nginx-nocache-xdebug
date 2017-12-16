FROM kdelfour/supervisor-docker
LABEL Gezim Hoxha <hgezim@gmail.com>

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get install -y nginx php5-dev php5-mysql php5-fpm php5-xdebug ccze vim links ssh curl

# needs to be up here
RUN usermod -u 1000 www-data

# Set up fpm error logging
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini
#RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 12M/' /etc/php5/fpm/php.ini
RUN sed -i 's/;php_admin_flag\[log_errors\] = on/;php_admin_flag\[log_errors\] = on/' /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's!;php_admin_value\[error_log\] = /var/log/fpm-php\.www\.log!php_admin_value\[error_log\] = /var/log/fpm-php\.www\.log!' /etc/php5/fpm/pool.d/www.conf
RUN echo 'env[XDEBUG_CONFIG] = $XDEBUG_CONFIG' >> /etc/php5/fpm/pool.d/www.conf

# Create file for fpm logging
RUN touch /var/log/fpm-php.www.log
RUN chown www-data.www-data /var/log/fpm-php.www.log

# Fix xdebug settings
RUN { \
  echo 'zend_extension="/usr/lib/php5/20121212/xdebug.so"'; \
  echo 'xdebug.remote_enable = on'; \
  echo 'xdebug.idekey = "vagrant"'; \
  } >> /etc/php5/mods-available/xdebug.ini

WORKDIR /root/
RUN curl https://wordpress.org/latest.tar.gz -O

RUN tar xzf latest.tar.gz
RUN rm -rf latest.tar.gz
RUN mkdir /usr/share/nginx/wp_tmp && cp -r wordpress/* /usr/share/nginx/wp_tmp/
RUN cp /usr/share/nginx/wp_tmp/wp-config-sample.php /usr/share/nginx/wp_tmp/wp-config.php

# We map ./working_files from host to /usr/share/nginx/html in container
# run.sh checks if /usr/share/nginx/html/wordpress/ exists and creates it if it doesn't
# run.sh then copies /usr/share/nginx/wp_tmp/* to /usr/share/nginx/html/wordpress/ 
# So, this leaves us with wordpress code in host and container. Even if host deletes wordpress code, that's okay
# Then we also map ./src (Zip Recipes source code) to /usr/share/nginx/html/wordpress/wp-content/plugins/zip-recipes
# This seals the deal and we can make updates in host and container gets them for free. This way
# zip-recipes/ lives outside wordpress dir in reality
VOLUME /usr/share/nginx/html

EXPOSE 8080

RUN sudo chown -R www-data:www-data /usr/share/nginx/wp_tmp

ADD ./nginx_wordpress /etc/nginx/sites-enabled/
ADD ./run.sh /root/
RUN chmod +x ./run.sh

COPY ./supervisor_nginx.conf ./supervisor_fpm.conf ./supervisor_sshd.conf /etc/supervisor/conf.d/


# create wordpress db if it doesn't exist - actually, let's let this be created by mysql image

# update config file 
RUN sed -i "s/define('DB_NAME', 'database_name_here');/define('DB_NAME', 'wordpress');/"	/usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "s/define('DB_USER', 'username_here');/define('DB_USER', 'root');/"	/usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "s/define('DB_PASSWORD', 'password_here');/define('DB_PASSWORD', 'root');/"	/usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "s/define('DB_HOST', 'localhost');/define('DB_HOST', 'db');/"	/usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "s/define('WP_DEBUG', false);/define('WP_DEBUG', true);/"	/usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "81idefine('WP_DEBUG_LOG', true);" /usr/share/nginx/wp_tmp/wp-config.php
RUN sed -i "82idefine('WP_DEBUG_DISPLAY', true);" /usr/share/nginx/wp_tmp/wp-config.php

# setup ssh
RUN mkdir /var/run/sshd
RUN sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config  

# set root pass
RUN echo "root:Dockerzrdn!" | chpasswd

# that's it!
ENTRYPOINT [ "./run.sh" ]