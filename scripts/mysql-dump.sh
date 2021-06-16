#!/bin/bash

file_env DB_PASSWORD
file_env DB_USER
file_env DB_NAME

_main(){
	local dump_file="${__shared_dir}/${_TS}_backup_${DB_NAME}.sql"
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
	gzip -v -9 ${dump_file}
	ln -frs "${dumpfile}.gz" "${__shared_dir}/latest_backup_${DB_NAME}.sql.gz"
}

_main

#END
