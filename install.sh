#!/bin/bash

log="./log.txt"

echo "===========================================" >> "$log"
date +"Start install - %F %T" >> "$log"
echo "===========================================" >> "$log"

echo "Update system" | tee -a "$log"
apt update -y && apt upgrade -y 2>> "$log"
apt install curl unzip software-properties-common -y 2>> "$log"
add-apt-repository ppa:ondrej/php -y 2>> "$log"
apt update -y 2>> "$log"

echo "Install Apache" | tee -a "$log"
apt install apache2 libapache2-mod-php7.4 libapache2-mod-fcgid -y 2>> "$log"
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf 2>> "$log"
cp ./config/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf 2>> "$log"
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf 2>> "$log"
a2dismod mpm_event 2>> "$log"
a2enmod mpm_prefork 2>> "$log"
a2enmod php7.4 setenvif actions fcgid alias proxy_fcgi remoteip 2>> "$log"
chown -R www-data:www-data /var/www 2>> "$log"
rm -f /var/www/html/index.html
rm -f /var/www/html/index.nginx-debian.html
echo "<?php phpinfo(); ?>" > "/var/www/html/index.php"
systemctl restart apache2 2>> "$log"

echo "Install NGINX" | tee -a "$log"
apt install nginx -y 2>> "$log"
cp ./config/etc/nginx/nginx.conf /etc/nginx/nginx.conf 2>> "$log"
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default 2>> "$log"
systemctl restart nginx 2>> "$log"

echo "Install MariaDB" | tee -a "$log"
apt install mariadb-server -y 2>> "$log"
cp ./config/etc/mysql/conf.d/my.cnf /etc/mysql/conf.d/my.cnf 2>> "$log"
systemctl restart mariadb

echo "Install PHP" | tee -a "$log"
apt install php7.4 php7.4-fpm php7.4-mysql php7.4-mysqli php7.4-curl php7.4-json php7.4-cgi php7.4-gd php7.4-zip php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-gmp -y 2>> "$log"
systemctl restart php7.4-fpm 2>> "$log"

echo "Install Memcached" | tee -a "$log"
apt install memcached php-memcached -y 2>> "$log"

echo "Install FTP" | tee -a "$log"
apt install proftpd -y 2>> "$log"
cp ./config/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf 2>> "$log"
cp ./config/etc/proftpd/conf.d/custom.conf /etc/proftpd/conf.d/custom.conf 2>> "$log"
touch /etc/proftpd/ftpd.passwd
chmod o-rwx /etc/proftpd/ftpd.passwd
systemctl restart proftpd 2>> "$log"

mysql_secure_installation 2>> "$log"

echo "Install phpMyAdmin" | tee -a "$log"
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.1/phpMyAdmin-5.0.1-all-languages.tar.gz
tar xzf phpMyAdmin-5.0.1-all-languages.tar.gz 2>> "$log"
mkdir /usr/share/phpmyadmin 2>> "$log"
mv phpMyAdmin-5.0.1-all-languages/* /usr/share/phpmyadmin 2>> "$log"
rm phpMyAdmin-5.0.1-all-languages.tar.gz 2>> "$log"
rm -rf phpMyAdmin-5.0.1-all-languages 2>> "$log"
mkdir /usr/share/phpmyadmin/tmp 2>> "$log"
chmod 777 /usr/share/phpmyadmin/tmp 2>> "$log"
cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php 2>> "$log"
ln -s /usr/share/phpmyadmin /var/www/html 2>> "$log"
mysql -e "update mysql.user set plugin='' where user='root';"
systemctl restart mariadb

echo "Install Composer" | tee -a "$log"
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php

echo "===========================================" >> "$log"
date +"Finished - %F %T" >> "$log"
echo "===========================================" >> "$log"
