#!/bin/bash

file_env DB_USER
file_env DB_PASSWORD
if [ -n "${DB_ROOT_USER:-}" ]; then
	file_env DB_ROOT_USER
	file_env DB_ROOT_PASSWORD
fi
file_env DB_NAME

backup_file=

# subscript help
_sub_usage(){
	cat >> /dev/stderr <<-EOF
	usage: ${_script_exec_helpname}

	Help for the subscript
	EOF
}

__restore_method="_restore_database"
__conn_user="DB_USER"

_restore_database(){
	local _backup_file="${backup_file%.gz}" _conn=
	_conn="${!__conn_user}"
	log_inf "Restoring ${DB_NAME} as ${_conn}"
	gunzip "${backup_file}.gz"
	psql ${*} -C -U "${_conn}" -h "${DB_HOST}" "${DB_NAME}" < "${_backup_file}"
}

_restore_all_databases(){
	local _backup_file="${backup_file%.gz}" _conn=
	_conn="${!__conn_user}"
	log_inf "Restoring all databases as ${_conn}"
	gunzip "${backup_file}"
	psql ${*} -C -U "${_conn}" -h "${DB_HOST}" postgres -f "${_backup_file}"
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
				__restore_method="_restore_all_databases"
				;;
			--root)
				if [ -z "${DB_ROOT_USER:-}" ]; then
					log_err "No root user infos provided. Please fill DB_ROOT_USER and DB_ROOT_PASSWORD variables."
					exit 1
				fi
				__conn_user="DB_ROOT_USER"
				;;
			*)
				if [ -s "${__shared_dir}/${1}" ]; then
					backup_file="${__shared_dir}/${1}"
				else
					_args+=("${1}")
				fi
				;;
		esac
		shift
	done
	_setup_pgpass

	if [ -n "${backup_latest_}" ]; then
		log_err "No backup properly provided, please check your arguments"
		exit 1
	fi
	${__restore_method} ${_args[@]}
}

_main "${@}"

#END
