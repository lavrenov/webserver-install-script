#!/bin/bash

echo "Update system"
apt-get update -y
apt-get upgrade -y

echo "Install NGINX"
apt-get install nginx -y
cp ./config/etc/nginx/nginx.conf /etc/nginx/nginx.conf
systemctl enable nginx
systemctl start nginx

echo "Install PHP"
apt-get install php php-fpm -y
systemctl enable php7.2-fpm
systemctl start php7.2-fpm
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default
cp ./config/etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini
cp ./config/etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini
systemctl restart nginx

echo "Install MariaDB"
apt-get install mariadb-server -y
systemctl enable mariadb
systemctl start mariadb
mysql_secure_installation
apt-get install php-mysql php-mysqli -y
systemctl restart php7.2-fpm

echo "Install phpMyAdmin"
apt-get install phpmyadmin
cp ./config/etc/nginx/sites-enabled/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
systemctl reload nginx

echo "Install memcached"
apt-get install memcached php-memcached
systemctl enable memcached
systemctl start memcached
systemctl restart php7.2-fpm

echo "Install FTP"
apt-get install proftpd
cp ./config/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf
cp ./config/etc/proftpd/conf.d/custom.conf /etc/proftpd/conf.d/custom.conf
systemctl enable proftpd
systemctl restart proftpd

echo "Install Apache"
apt-get install apache2 libapache2-mod-php
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod php7.2
a2enmod setenvif
systemctl enable apache2
systemctl start apache2
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default
systemctl restart nginx
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf
a2enmod remoteip
systemctl restart apache2

echo "Set owner www-data to /var/www"
chown -R www-data:www-data /var/www
