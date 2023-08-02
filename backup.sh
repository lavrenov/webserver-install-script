#!/bin/bash

. $(dirname "$0")/settings

TASK=$1

if [[ "${TASK}" == "daily" || "${TASK}" == "weekly" || "${TASK}" == "monthly" || "${TASK}" == "yearly" ]]; then
	if [[ "${TASK}" == "daily" ]]; then
		BACKUP_COUNT=30
	fi

	if [[ "${TASK}" == "weekly" ]]; then
		BACKUP_COUNT=12
	fi

	if [[ "${TASK}" == "monthly" ]]; then
		BACKUP_COUNT=12
	fi

	if [[ "${TASK}" == "yearly" ]]; then
		BACKUP_COUNT=3
	fi

	for USERNAME in $(members --all webusers); do
		if [[ -n "${USERNAME}" ]]; then
			DATE=$(date +%Y-%m-%d)
			BACKUP_USER_DIR=${WWW_DIR}/${USERNAME}/backups
			BACKUP_DATE_DIR=${BACKUP_USER_DIR}/${TASK}/${DATE}
			BACKUP_LIST=${WWW_DIR}/${USERNAME}/backup.list

			for backup in $(cat ${BACKUP_LIST}); do
				IFS='=' read -ra site <<<"${backup}"

				mkdir -p ${BACKUP_DATE_DIR}/${site[0]}
				cp -aRL ${WWW_DIR}/${USERNAME}/sites/${site[0]} ${BACKUP_DATE_DIR} 2>/dev/null || :
				rm -Rf ${BACKUP_DATE_DIR}/${site[0]}/log
				rm -Rf ${BACKUP_DATE_DIR}/${site[0]}/tmp

				mkdir -p ${BACKUP_DATE_DIR}/${site[0]}/configs/apache2
				cp -aRL /etc/apache2/sites-enabled/${site[0]}.conf ${BACKUP_DATE_DIR}/${site[0]}/configs/apache2/${site[0]}.conf 2>/dev/null || :

				mkdir -p ${BACKUP_DATE_DIR}/${site[0]}/configs/nginx
				cp -aRL /etc/nginx/sites-enabled/${site[0]}.conf ${BACKUP_DATE_DIR}/${site[0]}/configs/nginx/${site[0]}.conf 2>/dev/null || :

				mkdir -p ${BACKUP_DATE_DIR}/${site[0]}/configs/php7.4-fpm
				cp -aRL /etc/php/7.4/fpm/pool.d/${USERNAME}_${site[0]}.conf ${BACKUP_DATE_DIR}/${site[0]}/configs/php7.4-fpm/${USERNAME}_${site[0]}.conf 2>/dev/null || :

				mkdir -p ${BACKUP_DATE_DIR}/${site[0]}/configs/php8.0-fpm
            	cp -aRL /etc/php/8.0/fpm/pool.d/${USERNAME}_${site[0]}.conf ${BACKUP_DATE_DIR}/${site[0]}/configs/php8.0-fpm/${USERNAME}_${site[0]}.conf 2>/dev/null || :

				if [[ -n "${site[1]}" ]]; then
					mkdir -p ${BACKUP_DATE_DIR}/${site[0]}/sql
					mysqldump -u${DB_USER} -p${DB_PASS} ${site[1]} >${BACKUP_DATE_DIR}/${site[0]}/sql/${site[1]}.sql
				fi

				cd ${BACKUP_DATE_DIR}
				tar --create --gzip --file=${site[0]}.tgz ${site[0]}
				rm -Rf ${site[0]}

				find "${BACKUP_USER_DIR}/${TASK}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rnk1 | awk 'NR>'"${BACKUP_COUNT}"' { sub(/^\S+ /, "", $0); system("rm -r -f \"" $0 "\"")}'

				if [[ -n "${BUCKET}" ]] && [[ -n "${ENDPOINT_URL}" ]]; then
					/usr/local/bin/aws s3 cp ${BACKUP_DATE_DIR} "s3://${BUCKET}/backup/${USERNAME}/${TASK}/${DATE}" --recursive --quiet --endpoint-url ${ENDPOINT_URL}
				fi
			done

			chown -R ${USERNAME}:${USERNAME} ${BACKUP_USER_DIR}
		fi
	done
else
	echo "Required parameters not entered (backup.sh [daily|weekly|monthly|yearly])"
fi
