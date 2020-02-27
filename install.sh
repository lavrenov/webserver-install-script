#!/bin/bash

log="./log.txt"

echo "===========================================" >> "$log"
date +"Start install - %F %T" >> "$log"
echo "===========================================" >> "$log"

echo "Update system" | tee -a "$log"
apt update -y && apt upgrade -y 2>> "$log"
apt install software-properties-common -y 2>> "$log"
add-apt-repository ppa:ondrej/php -y 2>> "$log"

echo "Install Apache" | tee -a "$log"
apt install apache2 libapache2-mod-fcgid -y 2>> "$log"
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf 2>> "$log"
cp ./config/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf 2>> "$log"
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf 2>> "$log"
a2dismod mpm_event 2>> "$log"
a2enmod mpm_prefork 2>> "$log"
a2enmod php7.2 setenvif actions fcgid alias proxy_fcgi remoteip 2>> "$log"
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

echo "Install PHP" | tee -a "$log"
apt install php7.2 php7.2-fpm libapache2-mod-php7.2 php7.2-mysql php7.2-mysqli php7.2-curl php7.2-json php7.2-cgi php7.2-gd php7.2-zip php7.2-mbstring php7.2-xml php7.2-xmlrpc -y 2>> "$log"
cp ./config/etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini 2>> "$log"
cp ./config/etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini 2>> "$log"
systemctl restart php7.2-fpm 2>> "$log"

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

echo "===========================================" >> "$log"
date +"Finished - %F %T" >> "$log"
echo "===========================================" >> "$log"