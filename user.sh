#!/bin/bash

action=$1
username=$2
password=$3
homeDir="/var/www/$username"

if [[ -n "$username" ]] && [[ -n "$action" ]];
then
    # Add user
    if [[ "$action" == "add" ]];
    then
        useradd "$username" -p "$password" -d "$homeDir" -m -s /bin/bash
	uid=$(id -u "$username")
	ugid=$(id -g "$username")
	echo $password | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name="$username" --uid="$uid" --gid="$ugid" --home="/var/www/$username" --shell=/bin/false
    fi

    # Remove user
    if [[ "$action" == "remove" ]];
    then
        userdel -r "$username"
	ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name="$username" --delete-user
    fi
else
    echo "Required parameters not entered"
fi
