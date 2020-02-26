#!/bin/bash

log="./log.txt"

echo "===========================================" >> "$log"
date +"Start install - %F %T" >> "$log"
echo "===========================================" >> "$log"

echo "Update system" | tee -a "$log"
apt-get update -y 2>> "$log"
apt-get upgrade -y 2>> "$log"

echo "Install NGINX" | tee -a "$log"
apt-get install nginx -y 2>> "$log"
cp ./config/etc/nginx/nginx.conf /etc/nginx/nginx.conf 2>> "$log"
systemctl enable nginx 2>> "$log"
systemctl start nginx 2>> "$log"

echo "Install PHP" | tee -a "$log"
apt-get install php php-fpm -y 2>> "$log"
systemctl enable php7.2-fpm 2>> "$log"
systemctl start php7.2-fpm 2>> "$log"
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default 2>> "$log"
cp ./config/etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini 2>> "$log"
cp ./config/etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini 2>> "$log"
systemctl restart nginx 2>> "$log"

echo "Install MariaDB" | tee -a "$log"
apt-get install mariadb-server -y 2>> "$log"
systemctl enable mariadb 2>> "$log"
systemctl start mariadb 2>> "$log"
mysql_secure_installation 2>> "$log"
apt-get install php-mysql php-mysqli -y 2>> "$log"
systemctl restart php7.2-fpm 2>> "$log"

echo "Install phpMyAdmin" | tee -a "$log"
apt-get install phpmyadmin -y 2>> "$log"
cp ./config/etc/nginx/sites-enabled/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf 2>> "$log"
systemctl reload nginx 2>> "$log"

echo "Install memcached" | tee -a "$log"
apt-get install memcached php-memcached -y 2>> "$log"
systemctl enable memcached 2>> "$log"
systemctl start memcached 2>> "$log"
systemctl restart php7.2-fpm 2>> "$log"

echo "Install FTP" | tee -a "$log"
apt-get install proftpd -y 2>> "$log"
cp ./config/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf 2>> "$log"
cp ./config/etc/proftpd/conf.d/custom.conf /etc/proftpd/conf.d/custom.conf 2>> "$log"
touch /etc/proftpd/ftpd.passwd
chmod o-rwx /etc/proftpd/ftpd.passwd
systemctl enable proftpd 2>> "$log"
systemctl restart proftpd 2>> "$log"

echo "Install Apache" | tee -a "$log"
apt-get install apache2 libapache2-mod-php -y 2>> "$log"
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf 2>> "$log"
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf 2>> "$log"
a2dismod mpm_event 2>> "$log"
a2enmod mpm_prefork 2>> "$log"
a2enmod php7.2 2>> "$log"
a2enmod setenvif 2>> "$log"
systemctl enable apache2 2>> "$log"
systemctl start apache2 2>> "$log"
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default 2>> "$log"
systemctl restart nginx 2>> "$log"
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf 2>> "$log"
a2enmod remoteip 2>> "$log"
systemctl restart apache2 2>> "$log"
chown -R www-data:www-data /var/www 2>> "$log"

echo "===========================================" >> "$log"
date +"Finished - %F %T" >> "$log"
echo "===========================================" >> "$log"

sleep 2
