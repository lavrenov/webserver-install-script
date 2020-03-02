#!/bin/bash

action=$1
username=$2
password=$3
homeDir="/var/www/${username}"
phpFpmPoolConf="/etc/php/7.4/fpm/pool.d/${username}.conf"

if [[ -n "${username}" ]] && [[ -n "${action}" ]];
then
    # Add user
    if [[ "${action}" == "add" ]];
    then
        useradd "${username}" -p "${password}" -d "${homeDir}" -m -s /bin/bash
        uid=$(id -u "${username}")
        ugid=$(id -g "${username}")
        echo ${password} | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name="${username}" --uid="${uid}" --gid="${ugid}" --home="/var/www/${username}" --shell=/bin/false
        mkdir -p "${homeDir}/php"
        cp ./config/template/php7.4-fpm.conf "${phpFpmPoolConf}"
        sed -i "s/%POOLNAME%/${username}/g" "${phpFpmPoolConf}"
        sed -i "s/%USERNAME%/${username}/g" "${phpFpmPoolConf}"
        sed -i "s/%SITENAME%//g" "${phpFpmPoolConf}"
        systemctl restart php7.4-fpm
    fi

    # Remove user
    if [[ "${action}" == "remove" ]];
    then
	    systemctl stop php7.4-fpm
        userdel -r "${username}"
	    ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name="${username}" --delete-user
	    rm -f "/etc/php/7.4/fpm/pool.d/${username}.conf"
	    systemctl start php7.4-fpm
    fi
else
    echo "Required parameters not entered"
fi
