#!/bin/bash

echo
echo 'Select controller'
PS3='Your choose: '
select CONTROLLER in "user" "site"
do
	break
done

echo
echo 'Select action'
PS3='Your choose: '
select ACTION in "add" "remove"
do
	break
done

if [[ "${CONTROLLER}" == "user" ]];
then
	if  [[ "${ACTION}" == "add" ]];
	then
		echo
		echo -n "Enter username "
    	read USERNAME

    	echo -n "Enter password "
    	read PASSWORD

        PHPFPMPOOL_CONF="/etc/php/7.4/fpm/pool.d/${USERNAME}.conf"
        HOME_DIR="/var/www/${USERNAME}"

		useradd "${USERNAME}" -p "${PASSWORD}" -d "${HOME_DIR}" -m -s /bin/bash
        usermod -aG webusers "${USERNAME}"

        USER_ID=$(id -u "${USERNAME}")
        USER_GROUP_ID=$(id -g "${USERNAME}")

        echo ${PASSWORD} | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name="${USERNAME}" --uid="${USER_ID}" --gid="${USER_GROUP_ID}" --home="${HOME_DIR}" --shell=/bin/false >> /dev/null
        mkdir -p "${HOME_DIR}/php"
        cp ./config/template/php7.4-fpm.conf "${PHPFPMPOOL_CONF}"
        sed -i "s/%POOLNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
        sed -i "s/%USERNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
        sed -i "s/%SITENAME%//g" "${PHPFPMPOOL_CONF}"
        systemctl restart php7.4-fpm

        USER_EXISTS=`members --all webusers | grep -c "${USERNAME}"`
        if [[ "${USER_EXISTS}" == "1" ]];
        then
            echo "User \"${USERNAME}\" was created."
        else
            echo "User \"${USERNAME}\" was not created."
        fi
	fi
	if  [[ "${ACTION}" == "remove" ]];
	then
		echo
		echo 'Select username'
		PS3='Your choose: '
		select USERNAME in `members --all webusers`
		do
		    echo
		    echo -n "Do you want remove user: \"${USERNAME}\"? [Y/n] "
            read CONFIRM
            if [[ "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]];
            then
                HOME_DIR="/var/www/${USERNAME}"
                PHPFPMPOOL_CONF="/etc/php/7.4/fpm/pool.d/${USERNAME}*"

			    systemctl stop php7.4-fpm
                killall -u "${USERNAME}"
                userdel "${USERNAME}"
                ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name="${USERNAME}" --delete-user >> /dev/null
                rm -f ${PHPFPMPOOL_CONF}
                systemctl start php7.4-fpm

                echo -n "Do you want remove user home dir: \"${HOME_DIR}\"? [Y/n] "
                read REMOVE_HOME_DIR
                if [[ "${REMOVE_HOME_DIR}" == "Y" || "${REMOVE_HOME_DIR}" == "y" ]];
                then
                    rm -Rf "${HOME_DIR}"
                fi

                USER_EXISTS=`members --all webusers | grep -c "${USERNAME}"`
                if [[ "${USER_EXISTS}" == "0" ]];
                then
                    echo "User \"${USERNAME}\" was removed."
                else
                    echo "User \"${USERNAME}\" was not removed."
                fi
			fi
			break
		done
	fi
fi

if [[ "${CONTROLLER}" == "site" ]];
then
	if  [[ "${ACTION}" == "add" ]];
	then
		echo
		echo 'Select user to add site'
		PS3='Your choose: '
		select USERNAME in `members --all webusers`
		do
		    echo
		    echo -n "Enter site domain name "
            read DOMAIN

            NGINX_SITE_DIR="/etc/nginx/sites-enabled/"
            APACHE_SITE_DIR="/etc/apache2/sites-enabled/"
            PHPFPMPOOL_CONF="/etc/php/7.4/fpm/pool.d/${USERNAME}_${DOMAIN}.conf"
            HOME_DIR="/var/www/${USERNAME}"
            SITE_DIR="${HOME_DIR}/sites/${DOMAIN}"

            cp -i ./config/template/nginx.http.conf "${NGINX_SITE_DIR}${DOMAIN}.conf"
            sed -i "s/%DOMAIN%/${DOMAIN}/g" "${NGINX_SITE_DIR}${DOMAIN}.conf"
            sed -i "s/%USERNAME%/${USERNAME}/g" "${NGINX_SITE_DIR}${DOMAIN}.conf"

            cp -i ./config/template/apache.host.conf "${APACHE_SITE_DIR}${DOMAIN}.conf"
            sed -i "s/%DOMAIN%/${DOMAIN}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
            sed -i "s/%USERNAME%/${USERNAME}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"

            mkdir -p "${SITE_DIR}/www"
            mkdir -p "${SITE_DIR}/tmp"
            mkdir -p "${SITE_DIR}/log/nginx"
            mkdir -p "${SITE_DIR}/log/apache"

            echo "<?php echo \"<h1>${DOMAIN}</h1>\"; ?>" > "${SITE_DIR}/www/index.php"

            chown -R "${USERNAME}":"${USERNAME}" "${SITE_DIR}"
            chmod -R 775 "${SITE_DIR}"

            echo -n "Create a separate php-fpm pool config for site? [Y/n] "
            read SEPARATE_POOL

            if [[ "${SEPARATE_POOL}" == "Y" || "${SEPARATE_POOL}" == "y" ]];
            then
                cp -i ./config/template/php7.4-fpm.conf "${PHPFPMPOOL_CONF}"
                sed -i "s/%POOLNAME%/${USERNAME}_${DOMAIN}/g" "${PHPFPMPOOL_CONF}"
                sed -i "s/%USERNAME%/${USERNAME}/g" "${PHPFPMPOOL_CONF}"
                sed -i "s/%SITENAME%/_${DOMAIN}/g" "${PHPFPMPOOL_CONF}"
                systemctl restart php7.4-fpm
                sed -i "s/%SITENAME%/_${DOMAIN}/g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
            else
                sed -i "s/%SITENAME%//g" "${APACHE_SITE_DIR}${DOMAIN}.conf"
            fi

            a2dissite 000-default

            systemctl reload nginx
            systemctl reload apache2

            break
		done
	fi
	if  [[ "${ACTION}" == "remove" ]];
	then
		echo
		echo 'Select user'
		PS3='Your choose: '
		select USERNAME in `members --all webusers`
		do
		    HOME_DIR="/var/www/${USERNAME}"
		    SITES_DIR="${HOME_DIR}/sites/"

		    echo
            echo 'Select site'
            PS3='Your choose: '
		    select DOMAIN in `ls ${SITES_DIR}`
		    do
		        echo
                echo -n "Do you want remove site: \"${DOMAIN}\"? [Y/n] "
                read CONFIRM
                if [[ "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]];
                then
                    NGINX_SITE_DIR="/etc/nginx/sites-enabled/"
                    APACHE_SITE_DIR="/etc/apache2/sites-enabled/"
                    PHPFPMPOOL_CONF="/etc/php/7.4/fpm/pool.d/${USERNAME}_${DOMAIN}.conf"
                    SITE_DIR="${SITES_DIR}${DOMAIN}"

		            rm -f "${NGINX_SITE_DIR}${DOMAIN}.conf"
                    rm -f "${APACHE_SITE_DIR}${DOMAIN}.conf"
                    rm -f "${PHPFPMPOOL_CONF}"

                    echo -n "Do you want remove site dir: \"${SITE_DIR}\"? [Y/n] "
                    read REMOVE_SITE_DIR
                    if [[ "${REMOVE_SITE_DIR}" == "Y" || "${REMOVE_SITE_DIR}" == "y" ]];
                    then
                        rm -Rf "${SITE_DIR}"
                    fi

                    systemctl restart php7.4-fpm
    		        systemctl reload nginx
                    systemctl reload apache2
                fi

                break
            done

            break
		done
	fi
fi
echo

sleep 1
