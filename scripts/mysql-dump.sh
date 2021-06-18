#!/bin/bash

file_env DB_PASSWORD
file_env DB_USER
file_env DB_NAME

_main(){
	local dump_basepath="${_TS}_backup_${DB_NAME}.sql" dumpfile=
	dumpfile="${__shared_dir}/${dump_basepath}"
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

	(
	cd ${__shared_dir}
	ln -fs "${dump_basepath}.gz" "latest_backup_${DB_NAME}.sql.gz"
	)
}

_main

#END
