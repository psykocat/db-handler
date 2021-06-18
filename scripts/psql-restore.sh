#!/bin/bash

if [ -n "${DB_USER:-}" ]; then
	file_env DB_USER
	file_env DB_PASSWORD
fi
file_env DB_ROOT_USER
file_env DB_ROOT_PASSWORD
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
__conn_user="DB_ROOT_USER"

_restore_database(){
	local _backup_file="${backup_file%.gz}" _conn=
	_conn="${!__conn_user}"
	log_inf "Restoring ${DB_NAME} as ${_conn}"
	gunzip -f -k "${backup_file}"
	psql ${*} --set ON_ERROR_STOP=on -U "${_conn}" -h "${DB_HOST}" "${DB_NAME}" < "${_backup_file}"
	rm -vf "${_backup_file}"
}

_restore_all_databases(){
	local _backup_file="${backup_file%.gz}" _conn=
	_conn="${!__conn_user}"
	log_inf "Restoring all databases as ${_conn}"
	gunzip -f -k "${backup_file}"
	psql ${*} --set ON_ERROR_STOP=on -U "${_conn}" -h "${DB_HOST}" postgres -f "${_backup_file}"
	rm -vf "${_backup_file}"
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
				__restore_method="_restore_all_databases"
				;;
			--user)
				if [ -z "${DB_USER:-}" ]; then
					log_err "No user infos provided. Please fill DB_USER and DB_PASSWORD variables."
					exit 1
				fi
				__conn_user="DB_USER"
				#DB_NAME=postgres
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

	if [ -z "${backup_file}" ]; then
		log_err "No backup properly provided, please check your arguments"
		exit 1
	fi
	${__restore_method} ${_args[@]}
}

_main "${@}"

#END
