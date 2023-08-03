#!/bin/bash

. $(dirname "$0")/settings

PHPVERSIONS=("7.4" "8.0" "8.2")
for PHPVERSION in ${PHPVERSIONS[@]}; do
	echo ${PHPVERSION}
done

echo
echo 'Select controller'
PS3='Your choose: '
select CONTROLLER in "user" "site" "database"; do
	break
done

echo
echo 'Select action'
PS3='Your choose: '
select ACTION in "add" "remove"; do
	break
done

if [[ "${CONTROLLER}" == "user" ]]; then
	if [[ "${ACTION}" == "add" ]]; then
		echo
		echo -n "Enter username "
		read USERNAME

		echo -n "Enter password "
		read PASSWORD

		HOME_DIR="${WWW_DIR}/${USERNAME}"
		useradd "${USERNAME}" -p "${PASSWORD}" -d "${HOME_DIR}" -m -s /bin/bash
		usermod -aG webusers "${USERNAME}"

		USER_ID=$(id -u "${USERNAME}")
		USER_GROUP_ID=$(id -g "${USERNAME}")

		echo ${PASSWORD} | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name="${USERNAME}" --uid="${USER_ID}" --gid="${USER_GROUP_ID}" --home="${HOME_DIR}" --shell=/bin/false >>/dev/null
		mkdir -p "${HOME_DIR}/php"

		for PHPVERSION in ${PHPVERSIONS[@]}; do
			PHPFPMPOOL_CONF="/etc/php/${PHPVERSION}/fpm/pool.d/${USERNAME}.conf"
			cp ./config/template/php-fpm.conf "${PHPFPMPOOL_CONF}"
			sed -i "s/%POOLNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
			sed -i "s/%USERNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
			sed -i "s/%PHPVERSION%/${PHPVERSION}/g" "${PHPFPMPOOL_CONF}"
			sed -i "s/%SITENAME%//g" "${PHPFPMPOOL_CONF}"
			systemctl restart php${PHPVERSION}-fpm
		done

		USER_EXISTS=$(members --all webusers | grep -c "${USERNAME}")
		if [[ "${USER_EXISTS}" == "1" ]]; then
			echo "User \"${USERNAME}\" was created."
		else
			echo "User \"${USERNAME}\" was not created."
		fi
	fi
	if [[ "${ACTION}" == "remove" ]]; then
		echo
		echo 'Select username'
		PS3='Your choose: '
		select USERNAME in $(members --all webusers); do
			echo
			echo -n "Do you want remove user: \"${USERNAME}\"? [Y/n] "
			read CONFIRM
			if [[ "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]]; then
				HOME_DIR="${WWW_DIR}/${USERNAME}"
				killall -u "${USERNAME}"
				userdel "${USERNAME}"
				ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name="${USERNAME}" --delete-user >>/dev/null

				for PHPVERSION in ${PHPVERSIONS[@]}; do
					PHPFPMPOOL_CONF="/etc/php/${PHPVERSION}/fpm/pool.d/${USERNAME}*"
					systemctl stop php${PHPVERSION}-fpm
					rm -f ${PHPFPMPOOL_CONF}
					systemctl start php${PHPVERSION}-fpm
				done

				echo -n "Do you want remove user home dir: \"${HOME_DIR}\"? [Y/n] "
				read REMOVE_HOME_DIR
				if [[ "${REMOVE_HOME_DIR}" == "Y" || "${REMOVE_HOME_DIR}" == "y" ]]; then
					rm -Rf "${HOME_DIR}"
				fi

				USER_EXISTS=$(members --all webusers | grep -c "${USERNAME}")
				if [[ "${USER_EXISTS}" == "0" ]]; then
					echo "User \"${USERNAME}\" was removed."
				else
					echo "User \"${USERNAME}\" was not removed."
				fi
			fi
			break
		done
	fi
fi

if [[ "${CONTROLLER}" == "site" ]]; then
	if [[ "${ACTION}" == "add" ]]; then
		echo
		echo 'Select user to add site'
		PS3='Your choose: '
		select USERNAME in $(members --all webusers); do
			echo
			echo -n "Enter site domain name "
			read DOMAIN

			echo
            echo 'Select PHP version'
            PS3='Your choose: '
            select PHPVERSION in ${PHPVERSIONS[@]}; do
            	break
            done

			NGINX_SITE_DIR="/etc/nginx/sites-available/"
			APACHE_SITE_DIR="/etc/apache2/sites-available/"
			PHPFPMPOOL_CONF="/etc/php/${PHPVERSION}/fpm/pool.d/${USERNAME}_${DOMAIN}.conf"
			HOME_DIR="${WWW_DIR}/${USERNAME}"
			SITE_DIR="${HOME_DIR}/sites/${DOMAIN}"

			cp -i ./config/template/nginx.http.conf "${NGINX_SITE_DIR}${DOMAIN}.conf"
			sed -i "s/%DOMAIN%/${DOMAIN}/g" "${NGINX_SITE_DIR}${DOMAIN}.conf"
			sed -i "s/%USERNAME%/${USERNAME}/g" "${NGINX_SITE_DIR}${DOMAIN}.conf"

			cp -i ./config/template/apache.host.conf "${APACHE_SITE_DIR}${DOMAIN}.conf"
			sed -i "s/%DOMAIN%/${DOMAIN}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
			sed -i "s/%USERNAME%/${USERNAME}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
			sed -i "s/%PHPVERSION%/${PHPVERSION}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"

			mkdir -p "${SITE_DIR}/www"
			mkdir -p "${SITE_DIR}/tmp"
			mkdir -p "${SITE_DIR}/log/nginx"
			mkdir -p "${SITE_DIR}/log/apache"

			echo "<?php echo \"<h1>${DOMAIN}</h1>\"; ?>" >"${SITE_DIR}/www/index.php"

			chown -R "${USERNAME}":"${USERNAME}" "${SITE_DIR}"
			chmod -R 775 "${SITE_DIR}"

			echo
			echo -n "Create a separate php-fpm pool config for site? [Y/n] "
			read SEPARATE_POOL

			if [[ "${SEPARATE_POOL}" == "Y" || "${SEPARATE_POOL}" == "y" ]]; then
				cp -i ./config/template/php-fpm.conf "${PHPFPMPOOL_CONF}"
				sed -i "s/%POOLNAME%/${USERNAME}_${DOMAIN}/g" "${PHPFPMPOOL_CONF}"
				sed -i "s/%USERNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
				sed -i "s/%SITENAME%/_${DOMAIN}/g" "${PHPFPMPOOL_CONF}"
				sed -i "s/%PHPVERSION%/${PHPVERSION}/g" "${PHPFPMPOOL_CONF}"
				systemctl restart php${PHPVERSION}-fpm
				sed -i "s/%SITENAME%/_${DOMAIN}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
			else
				sed -i "s/%SITENAME%//g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
			fi

			ln -s "${NGINX_SITE_DIR}${DOMAIN}.conf" /etc/nginx/sites-enabled/${DOMAIN}.conf
			a2ensite ${DOMAIN}.conf

			systemctl reload nginx
			systemctl reload apache2

			break
		done
	fi
	if [[ "${ACTION}" == "remove" ]]; then
		echo
		echo 'Select user'
		PS3='Your choose: '
		select USERNAME in $(members --all webusers); do
			HOME_DIR="${WWW_DIR}/${USERNAME}"
			SITES_DIR="${HOME_DIR}/sites/"

			echo
			echo 'Select site'
			PS3='Your choose: '
			select DOMAIN in $(ls ${SITES_DIR}); do
				echo
				echo -n "Do you want remove site: \"${DOMAIN}\"? [Y/n] "
				read CONFIRM
				if [[ "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]]; then
					sudo rm "/etc/nginx/sites-enabled/${DOMAIN}.conf"
					a2dissite ${DOMAIN}.conf

					NGINX_SITE_DIR="/etc/nginx/sites-available/"
					APACHE_SITE_DIR="/etc/apache2/sites-available/"
					SITE_DIR="${SITES_DIR}${DOMAIN}"

					echo -n "Do you want remove site dir: \"${SITE_DIR}\"? [Y/n] "
					read REMOVE_SITE_DIR
					if [[ "${REMOVE_SITE_DIR}" == "Y" || "${REMOVE_SITE_DIR}" == "y" ]]; then
						rm -Rf "${SITE_DIR}"
					fi

					rm -f "${NGINX_SITE_DIR}${DOMAIN}.conf"
					rm -f "${APACHE_SITE_DIR}${DOMAIN}.conf"
					for PHPVERSION in ${PHPVERSIONS[@]}; do
						PHPFPMPOOL_CONF="/etc/php/${PHPVERSION}/fpm/pool.d/${USERNAME}_${DOMAIN}.conf"
						rm -f "${PHPFPMPOOL_CONF}"
						systemctl restart php${PHPVERSION}-fpm
					done
					systemctl reload nginx
					systemctl reload apache2
				fi

				break
			done

			break
		done
	fi
fi

if [[ "${CONTROLLER}" == "database" ]]; then
	if [[ "${ACTION}" == "add" ]]; then
		echo
		echo 'Select user'
		PS3='Your choose: '
		select USERNAME in $(members --all webusers); do
			echo
			echo -n "Enter database name "
			read DATABASE

			echo -n "Enter password "
			read PASSWORD

			if [[ -n "${DATABASE}" ]] && [[ -n "${PASSWORD}" ]]; then
				mysql -u${DB_USER} -p${DB_PASS} -e "CREATE USER '${USERNAME}_${DATABASE}'@'localhost' IDENTIFIED BY '${PASSWORD}';"
				mysql -u${DB_USER} -p${DB_PASS} -e "CREATE DATABASE IF NOT EXISTS ${USERNAME}_${DATABASE};"
				mysql -u${DB_USER} -p${DB_PASS} -e "GRANT ALL PRIVILEGES ON ${USERNAME}_${DATABASE}.* TO '${USERNAME}_${DATABASE}'@'localhost';"
				mysql -u${DB_USER} -p${DB_PASS} -e "FLUSH PRIVILEGES;"

				DATABASE_EXISTS=$(mysql -u${DB_USER} -p${DB_PASS} -e "show databases" | tr -d "| " | grep -c "${USERNAME}_${DATABASE}")
				if [[ "${DATABASE_EXISTS}" == "1" ]]; then
					echo "Database \"${USERNAME}_${DATABASE}\" was created."
					echo "Username: ${USERNAME}_${DATABASE}"
					echo "Password: ${PASSWORD}"
				else
					echo "Database \"${USERNAME}_${DATABASE}\" was not created."
				fi
			fi

			break
		done
	fi
	if [[ "${ACTION}" == "remove" ]]; then
		echo
		echo 'Select user'
		PS3='Your choose: '
		select USERNAME in $(members --all webusers); do
			echo
			echo 'Select database'
			PS3='Your choose: '
			select DATABASE in $(mysql -u${DB_USER} -p${DB_PASS} -e "show databases" | tr -d "| " | grep ${USERNAME}_); do
				echo
				echo -n "Do you want remove database: \"${DATABASE}\"? [Y/n] "
				read CONFIRM
				if [[ "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]]; then
					mysql -u${DB_USER} -p${DB_PASS} -e "DROP DATABASE IF EXISTS ${DATABASE};"
					mysql -u${DB_USER} -p${DB_PASS} -e "DROP USER IF EXISTS '${DATABASE}'@'localhost';"
					mysql -u${DB_USER} -p${DB_PASS} -e "FLUSH PRIVILEGES;"

					DATABASE_EXISTS=$(mysql -u${DB_USER} -p${DB_PASS} -e "show databases" | tr -d "| " | grep -c "${DATABASE}")
					if [[ "${DATABASE_EXISTS}" == "0" ]]; then
						echo "Database \"${DATABASE}\" was removed."
					else
						echo "Database \"${DATABASE}\" was not removed."
					fi
				fi

				break
			done

			break
		done
	fi
fi

echo
