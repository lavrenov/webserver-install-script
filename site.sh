#!/bin/bash

action=$1
site=$2
username=$3
sepPool=$4
nginxSiteDir="/etc/nginx/sites-enabled/"
apacheSiteDir="/etc/apache2/sites-enabled/"
phpFpmPoolConf="/etc/php/7.4/fpm/pool.d/${username}_${site}.conf"
wwwDir="/var/www/${username}/"

if [[ -n "${site}" ]] && [[ -n "${action}" ]] && [[ -n "${username}" ]];
then
    # Add site
    if [[ "${action}" == "add" ]];
    then
        cp -i ./config/template/nginx.http.conf "${nginxSiteDir}${site}.conf"
        sed -i "s/%DOMAIN%/${site}/g" "${nginxSiteDir}${site}.conf"
        sed -i "s/%USERNAME%/${username}/g" "${nginxSiteDir}${site}.conf"

        cp -i ./config/template/apache.host.conf "${apacheSiteDir}${site}.conf"
        sed -i "s/%DOMAIN%/${site}/g" "${apacheSiteDir}${site}.conf"
        sed -i "s/%USERNAME%/${username}/g" "${apacheSiteDir}${site}.conf"

        mkdir -p "${wwwDir}${site}/www"
        mkdir -p "${wwwDir}${site}/tmp"
        mkdir -p "${wwwDir}${site}/log/nginx"
        mkdir -p "${wwwDir}${site}/log/apache"

        echo "<?php echo \"<h1>${site}</h1>\"; ?>" > "${wwwDir}${site}/www/index.php"

        chown -R "${username}":"${username}" "${wwwDir}${site}"
        chmod -R 775 "${wwwDir}${site}"

        if [[ -n "${sepPool}" ]];
        then
            cp -i ./config/template/php7.4-fpm.conf "${phpFpmPoolConf}"
            sed -i "s/%POOLNAME%/${username}_${site}/g" "${phpFpmPoolConf}"
            sed -i "s/%USERNAME%/${username}/g" "${phpFpmPoolConf}"
            sed -i "s/%SITENAME%/_${site}/g" "${phpFpmPoolConf}"
            systemctl restart php7.4-fpm
            sed -i "s/%SITENAME%/_${site}/g" "${apacheSiteDir}${site}.conf"
        else
            sed -i "s/%SITENAME%//g" "${apacheSiteDir}${site}.conf"
        fi
    fi

    # Remove site
    if [[ "${action}" == "remove" ]];
    then
        rm -f "${nginxSiteDir}${site}.conf"
        rm -f "${apacheSiteDir}${site}.conf"
        rm -f "${phpFpmPoolConf}"
    fi

    systemctl reload nginx
    systemctl reload apache2
else
    echo "Required parameters not entered"
fi
