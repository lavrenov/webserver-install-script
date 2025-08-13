#!/bin/bash

. /etc/lsb-release
if [[ "${DISTRIB_CODENAME}" != "bionic" && "${DISTRIB_CODENAME}" != "focal" && "${DISTRIB_CODENAME}" != "jammy" ]]; then
	echo "Your OS is not Ubuntu 18, Ubuntu 20 or Ubuntu 22"
	sleep 1
	exit 1
fi

FORCE_INSTALL=$1
PHPVERSIONS=("7.4" "8.0" "8.1" "8.2" "8.3")

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install WebServer? [Y/n] "
	read USER_ANSWER
	if [[ "${USER_ANSWER}" != "Y" && "${USER_ANSWER}" != "y" ]]; then
		echo "Bye-bye"
		sleep 1
		exit 0
	fi
fi

log="./log.txt"

echo "===========================================" >>"$log"
date +"Start install - %F %T" >>"$log"
echo "===========================================" >>"$log"

echo "Update system" | tee -a "$log"
apt-get update -y && apt-get upgrade -y 2>>"$log"
apt-get install curl unzip software-properties-common apt-transport-https members logrotate -y 2>>"$log"
add-apt-repository ppa:ondrej/php -y
apt-get update -y 2>>"$log"
apt-get dist-upgrade -y 2>>"$log"
groupadd webusers 2>>"$log"

echo "Install Apache" | tee -a "$log"
apt-get install apache2 libapache2-mod-php7.4 libapache2-mod-fcgid -y 2>>"$log"
cp ./config/etc/apache2/ports.conf /etc/apache2/ports.conf 2>>"$log"
cp ./config/etc/apache2/mods-available/dir.conf /etc/apache2/mods-available/dir.conf 2>>"$log"
cp ./config/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf 2>>"$log"
cp ./config/etc/apache2/apache2.conf /etc/apache2/apache2.conf 2>>"$log"
cp ./config/etc/apache2/mods-available/remoteip.conf /etc/apache2/mods-available/remoteip.conf 2>>"$log"
a2dismod mpm_event 2>>"$log"
a2enmod mpm_prefork 2>>"$log"
a2enmod php7.4 setenvif actions fcgid alias proxy_fcgi remoteip rewrite headers 2>>"$log"
chown -R www-data:www-data /var/www 2>>"$log"
rm -f /var/www/html/index.html
echo "<?php phpinfo(); ?>" >"/var/www/html/index.php"
systemctl restart apache2 2>>"$log"

echo "Install NGINX" | tee -a "$log"
apt-get install nginx -y 2>>"$log"
cp ./config/etc/nginx/nginx.conf /etc/nginx/nginx.conf 2>>"$log"
cp ./config/etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default 2>>"$log"
mkdir /etc/nginx/vhosts-includes 2>>"$log"
cp ./config/etc/nginx/vhosts-includes/badbot.conf /etc/nginx/vhosts-includes/badbot.conf 2>>"$log"
rm -f /var/www/html/index.nginx-debian.html
systemctl restart nginx 2>>"$log"

echo "Install MariaDB" | tee -a "$log"
systemctl stop mysqld
apt-get purge mysql-server mysql-common mysql-server-core-* mysql-client-core-* 2>>"$log"
rm -Rf /var/lib/mysql/
rm -Rf /etc/mysql/
rm -Rf /var/log/mysql
deluser --remove-home mysql
delgroup mysql

wget -O- https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /usr/share/keyrings/mariadb-release-keyring.gpg
add-apt-repository "deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/mariadb-release-keyring.gpg] http://mirror.mephi.ru/mariadb/repo/10.6/ubuntu ${DISTRIB_CODENAME} main" -y
apt-get update -y 2>>"$log"

apt-get install mariadb-server -y 2>>"$log"
cp ./config/etc/mysql/conf.d/my.cnf /etc/mysql/conf.d/my.cnf 2>>"$log"
systemctl restart mariadb

for PHPVERSION in ${PHPVERSIONS[@]}; do
  echo "Install PHP ${PHPVERSION}" | tee -a "$log"
  apt-get install php${PHPVERSION} php${PHPVERSION}-fpm php${PHPVERSION}-mysql php${PHPVERSION}-curl php${PHPVERSION}-gd php${PHPVERSION}-zip php${PHPVERSION}-mbstring php${PHPVERSION}-xml php${PHPVERSION}-xmlrpc php${PHPVERSION}-gmp php${PHPVERSION}-memcached php${PHPVERSION}-intl php${PHPVERSION}-bcmath -y 2>>"$log"
  if [[ "${PHPVERSION}" == "7.4" ]]; then
    apt-get install php${PHPVERSION}-json
  fi

  systemctl restart php${PHPVERSION}-fpm 2>>"$log"
done

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install ProFTP? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install FTP" | tee -a "$log"
	apt-get install proftpd -y 2>>"$log"
	cp ./config/etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf 2>>"$log"
	cp ./config/etc/proftpd/conf.d/custom.conf /etc/proftpd/conf.d/custom.conf 2>>"$log"
	touch /etc/proftpd/ftpd.passwd
	chmod o-rwx /etc/proftpd/ftpd.passwd
	systemctl restart proftpd 2>>"$log"
fi

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install phpMyAdmin? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install phpMyAdmin" | tee -a "$log"
	wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
	tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz 2>>"$log"
	mkdir /usr/share/phpmyadmin 2>>"$log"
	mv phpMyAdmin-5.2.1-all-languages/* /usr/share/phpmyadmin 2>>"$log"
	rm phpMyAdmin-5.2.1-all-languages.tar.gz 2>>"$log"
	rm -rf phpMyAdmin-5.2.1-all-languages 2>>"$log"
	mkdir /usr/share/phpmyadmin/tmp 2>>"$log"
	chmod 777 /usr/share/phpmyadmin/tmp 2>>"$log"
	cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php 2>>"$log"
	BLOWFISH_SECRET=$(printf '%s' "${RANDOM}" | md5sum | awk '{print $1}')
	sed -i "s/\['blowfish_secret'\] = ''/\['blowfish_secret'\] = '${BLOWFISH_SECRET}'/g" "/usr/share/phpmyadmin/config.inc.php"
	ln -s /usr/share/phpmyadmin /var/www/html 2>>"$log"
	systemctl restart mariadb
fi

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install Fail2Ban? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install Fail2Ban" | tee -a "$log"
	apt-get install fail2ban -y 2>>"$log"
	cp ./config/etc/fail2ban/jail.d/base.conf /etc/fail2ban/jail.d/base.conf 2>>"$log"
	systemctl restart fail2ban
fi

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install IP Tables? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install IP Tables" | tee -a "$log"
	apt-get install iptables -y 2>>"$log"
	cp ./config/etc/iptables.start /etc/iptables.start 2>>"$log"
	cp ./config/etc/init.d/firewall.sh /etc/init.d/firewall.sh 2>>"$log"
	chmod +x /etc/iptables.start 2>>"$log"
	chmod +x /etc/init.d/firewall.sh 2>>"$log"
	update-rc.d firewall.sh defaults 2>>"$log"
	/etc/iptables.start
	service firewall.sh start
fi

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install Composer? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install Composer" | tee -a "$log"
	curl -sS https://getcomposer.org/installer -o composer-setup.php
	php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	rm -f composer-setup.php
fi

if [[ "${FORCE_INSTALL}" != "-f" ]]; then
	echo -n "Do you want to install AWS CLI? [Y/n] "
	read USER_ANSWER
else
	USER_ANSWER="Y"
fi
if [[ "${USER_ANSWER}" == "Y" || "${USER_ANSWER}" == "y" ]]; then
	echo "Install AWS CLI" | tee -a "$log"
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	./aws/install
	rm -Rf aws
	rm -f awscliv2.zip
fi

SETTINGS_FILE="./settings"
rm -rf ${SETTINGS_FILE}
echo "WWW_DIR=/var/www" >>${SETTINGS_FILE}
echo "DB_USER=root" >>${SETTINGS_FILE}
echo "DB_PASS=" >>${SETTINGS_FILE}
echo "BUCKET=" >>${SETTINGS_FILE}
echo "ENDPOINT_URL=" >>${SETTINGS_FILE}

echo "===========================================" >>"$log"
date +"Finished - %F %T" >>"$log"
echo "===========================================" >>"$log"

cat "$log"

errors=$(cat "$log" | grep "E:")
if [[ -n "${errors}" ]]; then
	echo "Installation finished with errors"
	exit 1
fi
