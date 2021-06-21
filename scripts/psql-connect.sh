#!/bin/bash

# Configure using simple user password
file_env DB_USER
file_env DB_PASSWORD
if [ -n "${DB_ROOT_USER:-}" ]; then
	file_env DB_ROOT_USER
	file_env DB_ROOT_PASSWORD
fi
file_env DB_NAME

__conn_user="DB_USER"

# subscript help
_sub_usage(){
	cat >> /dev/stderr <<-EOF
	usage: ${_script_exec_helpname}

	Help for the subscript
	EOF
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
				shift $#
				break
				;;
			-help|--help)
				_sub_usage
				exit
				;;
			--root)
				if [ -z "${DB_ROOT_USER:-}" ]; then
					log_err "No user infos provided. Please fill DB_ROOT_USER and DB_ROOT_PASSWORD variables."
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
	if [ ${#_args[*]} -eq 0 ]; then
		set -- -h "${DB_HOST}" -U "${!__conn_user}" "${DB_NAME}"
	fi
	_setup_pgpass
	log_inf psql "${@}"
	#psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} "${@}"
	psql "${@}"
}

_main "${@}"

#END
