#!/bin/bash

file_env DB_USER
file_env DB_PASSWORD
if [ -n "${DB_ROOT_USER:-}" ]; then
	file_env DB_ROOT_USER
	file_env DB_ROOT_PASSWORD
fi
file_env DB_NAME

# subscript help
_sub_usage(){
	cat >> /dev/stderr <<-EOF
	usage: ${_script_exec_helpname}

	Help for the subscript
	EOF
}

__dump_method="_dump_database"
__conn_user="DB_USER"

_dump_database(){
	local dump_basepath="${_TS}_backup_${DB_NAME}.sql" dumpfile= _conn=
	dumpfile="${__shared_dir}/${dump_basepath}"
	_conn="${!__conn_user}"
	log_inf "Dumping ${DB_NAME} as ${_conn}"
	pg_dump ${*} -c --if-exists -U "${_conn}" -h "${DB_HOST}" "${DB_NAME}" > "${dumpfile}"
	gzip -9 -v "${dumpfile}"
	(
	cd "${__shared_dir}"
	ln -fs "${dump_basepath}.gz" "latest_backup_${DB_NAME}.sql.gz"
	)
}

_dump_all_databases(){
	local dump_basepath="${_TS}_backup_all_databases.sql" dumpfile= _conn=
	dumpfile="${__shared_dir}/${dump_basepath}"
	_conn="${!__conn_user}"
	log_inf "Dumping all databases as ${_conn}"
	pg_dumpall ${*} -c --if-exists -U "${_conn}" -h "${DB_HOST}" > "${dumpfile}"
	gzip -9 -v "${dumpfile}"
	(
	cd "${__shared_dir}"
	ln -fs "${dump_basepath}.gz" "latest_backup_all_databases.sql.gz"
	)
}

# Input the command to execute in a _main() function
_main(){
	local _args=()

	while [ ${#} -gt 0 ]; do
		case ${1} in
			--debug)
				set -x
				;;
			--)
				shift;
				for _remain in ${@}; do
					_args+=("${_remain}")
				done
				unset -- _remain
				break
				;;
			-help|--help)
				_sub_usage
				exit
				;;
			--all)
				__dump_method="_dump_all_databases"
				;;
			--root)
				if [ -z "${DB_ROOT_USER:-}" ]; then
					log_err "No root user infos provided. Please fill DB_ROOT_USER and DB_ROOT_PASSWORD variables."
					exit 1
				fi
				__conn_user="DB_ROOT_USER"
				;;
			*)
				_args+=("${1}")
				;;
		esac
		shift
	done
	_setup_pgpass

	${__dump_method} ${_args[@]}
}

_main "${@}"

#END
