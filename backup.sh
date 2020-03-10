#!/bin/bash

USERNAME=$1
DB_USER=
DB_PASS=
DATE=`date +%Y-%m-%d_%H-%M-%S`
BACKUP_DIR=/backup/${USERNAME}/${DATE}
DATABASE_LIST=/tmp/databases.list
WWW_DIR=/var/www

mkdir -p ${BACKUP_DIR}/${USERNAME}/sql
cp -ar ${WWW_DIR}/${USERNAME}/. ${BACKUP_DIR}/${USERNAME}

mysql -u ${DB_USER} -p${DB_PASS} -e "show databases;" | grep "${USERNAME}_*" > ${DATABASE_LIST}

for database in `cat ${DATABASE_LIST}`
do
    mysqldump -u ${DB_USER} -p${DB_PASS} ${database} > ${BACKUP_DIR}/${USERNAME}/sql/${database}.sql
done

chown -R ${USERNAME}:${USERNAME} ${BACKUP_DIR}
rm -Rf ${BACKUP_DIR}/${USERNAME}/php
cd ${BACKUP_DIR}
tar -zcf ${DATE}.tar.gz ${USERNAME}
rm -Rf ${USERNAME}
rm -f ${DATABASE_LIST}
split -b 50M ${DATE}.tar.gz "${DATE}.tar.gz.part_"
rm -f ${DATE}.tar.gz
chown ${USERNAME}:${USERNAME} ${DATE}.tar.gz
