#!/bin/bash

. /etc/lsb-release
if [[ "${DISTRIB_CODENAME}" != "bionic" ]];
then
    echo "Your OS is not Ubuntu 18"
    sleep 1
    exit 1
fi

FORCE_INSTALL=$1

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install WebServer? [Y/n] "
    read USER_ANSWER
    if [[ "${USER_ANSWER}" != "Y" && "${USER_ANSWER}" != "y" ]];
    then
        echo "Bye-bye"
        sleep 1
        exit 0
    fi
fi

log="./log.txt"

echo "===========================================" >> "$log"
date +"Start install - %F %T" >> "$log"
echo "===========================================" >> "$log"

echo "Update system" | tee -a "$log"
apt-get update -y && apt-get upgrade -y 2>> "$log"
apt-get install curl unzip software-properties-common apt-transport-https -y 2>> "$log"
add-apt-repository ppa:ondrej/php -y
apt-get update -y 2>> "$log"
groupadd webusers 2>> "$log"

echo "Install Apache" | tee -a "$log"
apt-get install apache2 libapache2-mod-php7.4 libapache2-mod-fcgid -y 2>> "$log"
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf 2>> "$log"
cp ./config/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf 2>> "$log"
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf 2>> "$log"
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf 2>> "$log"
a2dismod mpm_event 2>> "$log"
a2enmod mpm_prefork 2>> "$log"
a2enmod php7.4 setenvif actions fcgid alias proxy_fcgi remoteip rewrite headers 2>> "$log"
chown -R www-data:www-data /var/www 2>> "$log"
rm -f /var/www/html/index.html
echo "<?php phpinfo(); ?>" > "/var/www/html/index.php"
systemctl restart apache2 2>> "$log"

echo "Install NGINX" | tee -a "$log"
apt-get install nginx -y 2>> "$log"
cp ./config/etc/nginx/nginx.conf /etc/nginx/nginx.conf 2>> "$log"
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default 2>> "$log"
rm -f /var/www/html/index.nginx-debian.html
systemctl restart nginx 2>> "$log"

echo "Install MariaDB" | tee -a "$log"
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' -y
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.ufscar.br/mariadb/repo/10.3/ubuntu bionic main' -y
apt-get update -y 2>> "$log"
apt-get install mariadb-server -y 2>> "$log"
cp ./config/etc/mysql/conf.d/my.cnf /etc/mysql/conf.d/my.cnf 2>> "$log"
systemctl restart mariadb

echo "Install PHP" | tee -a "$log"
apt-get install php7.4 php7.4-fpm php7.4-mysql php7.4-mysqli php7.4-curl php7.4-json php7.4-cgi php7.4-gd php7.4-zip php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-gmp php7.4-intl -y 2>> "$log"
systemctl restart php7.4-fpm 2>> "$log"

echo "Install FTP" | tee -a "$log"
apt-get install proftpd -y 2>> "$log"
cp ./config/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf 2>> "$log"
cp ./config/etc/proftpd/conf.d/custom.conf /etc/proftpd/conf.d/custom.conf 2>> "$log"
touch /etc/proftpd/ftpd.passwd
chmod o-rwx /etc/proftpd/ftpd.passwd
systemctl restart proftpd 2>> "$log"

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install phpMyAdmin? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
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
    BLOWFISH_SECRET=`printf '%s' "${RANDOM}" | md5sum | awk '{print $1}'`
    sed -i "s/\['blowfish_secret'\] = ''/\['blowfish_secret'\] = '${BLOWFISH_SECRET}'/g" "/usr/share/phpmyadmin/config.inc.php"
    ln -s /usr/share/phpmyadmin /var/www/html 2>> "$log"
    systemctl restart mariadb
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install Certbot? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install Certbot" | tee -a "$log"
    add-apt-repository ppa:certbot/certbot -y
    apt-get update -y 2>> "$log"
    apt-get install certbot -y 2>> "$log"
    apt-get install python-certbot-nginx -y 2>> "$log"
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install Fail2Ban? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install Fail2Ban" | tee -a "$log"
    apt-get install fail2ban -y 2>> "$log"
    cp ./config/etc/fail2ban/jail.d/defaults-debain.conf /etc/fail2ban/jail.d/defaults-debain.conf 2>> "$log"
    systemctl restart fail2ban
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install IP Tables? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install IP Tables" | tee -a "$log"
    apt-get install iptables -y 2>> "$log"
    cp ./config/etc/iptables.start /etc/iptables.start 2>> "$log"
    cp ./config/etc/init.d/firewall.sh /etc/init.d/firewall.sh 2>> "$log"
    chmod +x /etc/iptables.start 2>> "$log"
    chmod +x /etc/init.d/firewall.sh 2>> "$log"
    update-rc.d firewall.sh defaults 2>> "$log"
    service firewall.sh start
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install Memcached? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install Memcached" | tee -a "$log"
    apt-get install memcached php-memcached -y 2>> "$log"
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install Composer? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install Composer" | tee -a "$log"
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
fi

if [[ "${FORCE_INSTALL}" != "-f" ]];
then
    echo -n "Do you want to install Jenkins? [Y/n] "
    read USER_ANSWER
else
    USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]];
then
    echo "Install Jenkins" | tee -a "$log"
    apt-get install openjdk-8-jre -y 2>> "$log"
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update -y 2>> "$log"
    apt-get install jenkins -y 2>> "$log"
    cp ./config/etc/default/jenkins /etc/default/jenkins 2>> "$log"
    systemctl restart jenkins
fi

echo "===========================================" >> "$log"
date +"Finished - %F %T" >> "$log"
echo "===========================================" >> "$log"

cat "$log"

errors=`cat "$log" | grep "E:"`
if [[ -n "${errors}" ]]; then
  echo "Installation finished with errors"
  exit 1
fi
