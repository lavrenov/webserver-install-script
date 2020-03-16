#!/bin/bash

apt remove proftpd* --purge -y
apt remove memcached* --purge -y
apt remove php* --purge -y
apt remove mariadb* --purge -y
apt remove nginx* --purge -y
apt remove apache* --purge -y
apt remove certbot* --purge -y
apt remove openjdk-8-jre --purge -y
apt remove jenkins* --purge -y
apt remove fail2ban* --purge -y

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

apt autoremove
apt autoclean
apt clean
apt -f install
