# Bash script to install Web Server

[![Build](https://github.com/lavrenov/webserver-install-script/workflows/Build/badge.svg)](https://github.com/lavrenov/webserver-install-script)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/lavrenov/webserver-install-script?label=version)](https://github.com/lavrenov/webserver-install-script)
[![GitHub repo size](https://img.shields.io/github/repo-size/lavrenov/webserver-install-script)](https://github.com/lavrenov/webserver-install-script)
[![GitHub last commit](https://img.shields.io/github/last-commit/lavrenov/webserver-install-script)](https://github.com/lavrenov/webserver-install-script/commits/master)

## System requirements

The script is tested on Ubuntu 18.04

## What does this script install?

- Apache
- NGINX
- MariaDB 10.3
- PHP 7.4 + extensions (cgi, curl, fpm, gd, gmp, intl, json, mbstring, mysql, mysqli, xml, xmlrpc, zip)
- ProFTP
- phpMyAdmin 5.0.1
- Certbot
- Fail2Ban
- IP Tables
- Memcached
- Composer
- Jenkins

## How this is work

1. Install:
    ```
    sudo ./install.sh
    sudo mysql_secure_installation
    ```
2. Users
    - Add user:
        ```
        sudo user.sh add [username] [password]
        ```
    - Remove user:
        ```
        sudo user.sh remove [username]
        ```

3. Sites
    - Add site:
        ```
        sudo site.sh add [domain] [username] [separate fpm pool (y|n)
        ```
    - Remove site:
        ```
        sudo site.sh remove [domain] [username]
        ```
4. Uninstall:
    ```
    sudo ./uninstall.sh
    ``` 
