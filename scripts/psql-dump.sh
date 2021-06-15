#!/bin/bash

file_env DB_USER
file_env DB_PASSWORD
file_env DB_ROOT_USER
file_env DB_ROOT_PASSWORD
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
	local dumpfile="${__shared_dir}/${_TS}_backup_${DB_NAME}.sql" _conn=
	_conn="${!__conn_user}"
	pg_dump ${*} -C -U "${_conn}" -h "${DB_HOST}" "${DB_NAME}" > "${dumpfile}"
	gzip -9 -v "${dumpfile}"
}

_dump_all_databases(){
	local dumpfile="${__shared_dir}/${_TS}_backup_all.sql" _conn=
	_conn="${!__conn_user}"
	pg_dumpall ${*} -C -U "${_conn}" -h "${DB_HOST}" > "${dumpfile}"
	gzip -9 -v "${dumpfile}"
}

# Input the command to execute in a _main() function
_main(){
	local _args=()

	while [ ${#} -gt 0 ]; do
		case ${1} in
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
				__conn_user="DB_ROOT_USER"
				;;
			*)
				_args+=("${1}")
				;;
		esac
		shift
	done
	log_inf "Dumping database"
	pg_dump --help
	set -x

	_setup_pgpass

	${__dump_method} ${_args[@]}
}

_main "${@}"

#END
