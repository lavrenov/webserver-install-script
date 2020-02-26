#!/bin/bash

action=$1
username=$2
homeDir="/var/www/$username"

if [[ -n "$username" ]] && [[ -n "$action" ]];
then
    # Add user
    if [[ "$action" == "add" ]];
    then
        useradd "$username" -d "$homeDir" -m -s /bin/bash
    fi

    # Remove user
    if [[ "$action" == "remove" ]];
    then
        userdel -r "$username"
    fi
else
    echo "Required parameters not entered"
fi
