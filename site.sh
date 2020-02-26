#!/bin/bash

action=$1
site=$2
username=$3
nginxSiteDir="/etc/nginx/sites-enabled/"
apacheSiteDir="/etc/apache2/sites-enabled/"
wwwDir="/var/www/$username/"

if [[ -n "$site" ]] && [[ -n "$action" ]] && [[ -n "$username" ]];
then
    # Add site
    if [[ "$action" == "add" ]];
    then
        cp -i ./config/template/nginx.http.conf "$nginxSiteDir$site.conf"
        sed -i "s/%DOMAIN%/$site/g" "$nginxSiteDir$site.conf"
	sed -i "s/%USERNAME%/$username/g" "$nginxSiteDir$site.conf"

        cp -i ./config/template/apache.host.conf "$apacheSiteDir$site.conf"
        sed -i "s/%DOMAIN%/$site/g" "$apacheSiteDir$site.conf"
	sed -i "s/%USERNAME%/$username/g" "$apacheSiteDir$site.conf"

        mkdir -p "$wwwDir$site/www"
        mkdir -p "$wwwDir$site/tmp"
        mkdir -p "$wwwDir$site/log/nginx"
        mkdir -p "$wwwDir$site/log/apache"

        echo "<?php echo \"<h1>$site</h1>\"; ?>" > "$wwwDir$site/www/index.php"

        chown -R "$username":"$username" "$wwwDir$site"
        chmod -R 775 "$wwwDir$site"
    fi

    # Remove site
    if [[ "$action" == "remove" ]];
    then
        rm "$nginxSiteDir$site.conf"
        rm "$apacheSiteDir$site.conf"
        rm -R "$wwwDir$site/"
    fi

    systemctl reload nginx
    systemctl reload apache2
else
    echo "Required parameters not entered"
fi
