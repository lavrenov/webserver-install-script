#!/bin/bash

apt-get remove proftpd* --purge -y
apt-get remove memcached* --purge -y
apt-get remove php* --purge -y
apt-get remove mariadb* --purge -y
apt-get remove nginx* --purge -y
apt-get remove apache* --purge -y
apt-get remove certbot* --purge -y
apt-get remove openjdk-8-jre --purge -y
apt-get remove jenkins* --purge -y
apt-get remove fail2ban* --purge -y

rm -Rf /etc/proftpd/
rm -Rf /etc/php/
rm -Rf /etc/nginx/
rm -Rf /etc/apache2/
rm -Rf /var/www/
rm -Rf /var/lib/mysql/
rm -Rf /usr/share/phpmyadmin/
rm -Rf /usr/share/jenkins/
rm -f /etc/default/jenkins
rm -Rf /etc/fail2ban/
service firewall.sh stop
update-rc.d firewall.sh remove
rm -f /etc/iptables.start
rm -f /etc/init.d/firewall.sh

apt-get autoremove
apt-get autoclean
apt-get clean
apt-get -f install
