# Bash script to install Web Server

[![Build](https://github.com/lavrenov/webserver-install-script/workflows/Build/badge.svg)](https://github.com/lavrenov/webserver-install-script)
[![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/lavrenov/webserver-install-script?label=version)](https://github.com/lavrenov/webserver-install-script)
[![GitHub repo size](https://img.shields.io/github/repo-size/lavrenov/webserver-install-script)](https://github.com/lavrenov/webserver-install-script)
[![GitHub last commit](https://img.shields.io/github/last-commit/lavrenov/webserver-install-script)](https://github.com/lavrenov/webserver-install-script/commits/master)

## System requirements

The script is tested on **Ubuntu 18.04, 20.04**

## What does this script install?

- **Nginx** + **Apache** *(Nginx for static files, Apache for dynamic files)*
- **MariaDB 10.3**
- **PHP 7.4**
- **ProFTP** *(optional)*
- **phpMyAdmin 5.0.1** *(optional)*
- **Certbot** *(optional)*
- **Fail2Ban** *(optional)*
- **IP Tables** *(optional)*
- **Memcached** *(optional)*
- **Composer** *(optional)*
- **AWS CLI** *(optional)*

## How this is work

1. **Install:**
    ```
    sudo ./install.sh
    ```
    
2. **Users** and **Sites**

    For add or remove user, site or database launch script and follow instructions

    ```
    sudo ./menu.sh
    ```

3. **Firewall usage**   

    ```
    /etc/init.d/firewall.sh {start|stop|restart}
    ```
    
    Config file path /etc/iptables.start
    
4. **Certbot**

    launch script and follow instructions

    ```
    Cerbot
    ```
    
3. **Uninstall:**
    ```
    sudo ./uninstall.sh
    ``` 
