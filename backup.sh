#!/bin/bash

USERNAME=$1
DB_USER=
DB_PASS=
DATE=`date +%Y-%m-%d_%H-%M-%S`
BACKUP_USER_DIR=/backup/${USERNAME}
BACKUP_DATE_DIR=${BACKUP_USER_DIR}/${DATE}
BACKUP_COUNT=30
DATABASE_LIST=/tmp/databases.list
WWW_DIR=/var/www

if [[ -n "${USERNAME}" ]];
then
    mkdir -p ${BACKUP_DATE_DIR}/${USERNAME}/sql
    cp -ar ${WWW_DIR}/${USERNAME}/. ${BACKUP_DATE_DIR}/${USERNAME}

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
    split -b 50M ${DATE}.tar.gz "${DATE}.tar.gz.part_"
    rm -f ${DATE}.tar.gz
    chown ${USERNAME}:${USERNAME} ${DATE}.tar.gz

    find "${BACKUP_USER_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rnk1 | awk 'NR>'"${BACKUP_COUNT}"' { sub(/^\S+ /, "", $0); system("rm -r -f \"" $0 "\"")}'
else
    echo "Required parameters not entered (backup.sh [username])"
fi
