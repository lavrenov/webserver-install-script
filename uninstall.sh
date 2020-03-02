#!/bin/bash

apt remove proftpd* --purge -y
apt remove memcached* --purge -y
apt remove php* --purge -y
apt remove mariadb* --purge -y
apt remove nginx* --purge -y
apt remove apache* --purge -y

rm -Rf /etc/proftpd/
rm -Rf /etc/php/
rm -Rf /etc/nginx/
rm -Rf /etc/apache2/
rm -Rf /var/www/
rm -Rf /var/lib/mysql/
rm -Rf /usr/share/phpmyadmin/

apt autoremove
apt autoclean
apt clean
apt -f install
