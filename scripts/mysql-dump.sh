#!/bin/bash

file_env DB_PASSWORD
file_env DB_USER
file_env DB_NAME

_main(){
	local dump_file="${DBHANDLER_BACKUP_DIR}/${_TS}_backup_${DB_NAME}.sql"
	mysqldump \
		--add-drop-table \
		--compress \
		-h ${DB_HOST} \
		-p${DB_PASSWORD} \
		-P ${DB_PORT:-3306} \
		-u ${DB_USER} \
		--single-transaction \
		${DB_NAME} > ${dump_file}

	log_inf "Compressing database dump ..."
	gzip ${dump_file}
	(
	cd ${DBHANDLER_BACKUP_DIR}
	ln -fs ${dump_file#*/} backup_latest_${DB_NAME}.gz
}

_main

#END
