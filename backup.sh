#!/bin/bash

# MySQL
DB_USER=
DB_PASS=

# www directory
WWW_DIR=/var/www

# backup directory
BACKUP_DIR=/backup

# Backup count to store
BACKUP_COUNT=30

# S3
BUCKET=
ENDPOINT_URL=

USERNAME=$1
DATE=`date +%Y-%m-%d_%H-%M-%S`
BACKUP_USER_DIR=${BACKUP_DIR}/${USERNAME}
BACKUP_DATE_DIR=${BACKUP_USER_DIR}/${DATE}
DATABASE_LIST=/tmp/databases.list
SITES_LIST=/tmp/sites.list

if [[ -n "${USERNAME}" ]];
then
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/sql
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/ssl
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/configs/apache2
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/configs/nginx
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/configs/php7.4-fpm

    cp -aRL ${WWW_DIR}/${USERNAME}/. ${BACKUP_DATE_DIR}/${USERNAME}
    cp -aRL /etc/php/7.4/fpm/pool.d/${USERNAME}.conf ${BACKUP_DATE_DIR}/${USERNAME}/configs/php7.4-fpm/${USERNAME}.conf 2>/dev/null || :

    ls ${WWW_DIR}/${USERNAME} | grep -v php > ${SITES_LIST}
    for site in `cat ${SITES_LIST}`
    do
        cp -aRL /etc/letsencrypt/live/${site} ${BACKUP_DATE_DIR}/${USERNAME}/ssl 2>/dev/null || :
        cp -aRL /etc/apache2/sites-enabled/${site}.conf ${BACKUP_DATE_DIR}/${USERNAME}/configs/apache2/${site}.conf 2>/dev/null || :
        cp -aRL /etc/nginx/sites-enabled/${site}.conf ${BACKUP_DATE_DIR}/${USERNAME}/configs/nginx/${site}.conf 2>/dev/null || :
        cp -aRL /etc/php/7.4/fpm/pool.d/${USERNAME}_${site}.conf ${BACKUP_DATE_DIR}/${USERNAME}/configs/php7.4-fpm/${USERNAME}_${site}.conf 2>/dev/null || :
    done

    mysql -u ${DB_USER} -p${DB_PASS} -e "show databases;" | grep "${USERNAME}_*" > ${DATABASE_LIST}
    for database in `cat ${DATABASE_LIST}`
    do
        mysqldump -u ${DB_USER} -p${DB_PASS} ${database} > ${BACKUP_DATE_DIR}/${USERNAME}/sql/${database}.sql
    done

    chown -R ${USERNAME}:${USERNAME} ${BACKUP_DATE_DIR}
    rm -Rf ${BACKUP_DATE_DIR}/${USERNAME}/php
    cd ${BACKUP_DATE_DIR}
    tar -zcf ${DATE}.tar.gz ${USERNAME}
    rm -Rf ${USERNAME}
    rm -f ${DATABASE_LIST}
    rm -f ${SITES_LIST}
    split -b 50M ${DATE}.tar.gz "${DATE}.tar.gz.part_"
    rm -f ${DATE}.tar.gz
    chown ${USERNAME}:${USERNAME} ${BACKUP_USER_DIR}

    find "${BACKUP_USER_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rnk1 | awk 'NR>'"${BACKUP_COUNT}"' { sub(/^\S+ /, "", $0); system("rm -r -f \"" $0 "\"")}'

    if [[ -n "${BUCKET}" ]] && [[ -n "${ENDPOINT_URL}" ]];
    then
        aws s3 cp ${BACKUP_DATE_DIR} s3://${BUCKET}/backup/${USERNAME}/${DATE} --recursive --quiet --endpoint-url ${ENDPOINT_URL}
    fi
else
    echo "Required parameters not entered (backup.sh [username])"
fi
