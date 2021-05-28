#!/bin/bash

# Configure using simple user password
file_env DB_PASSWORD
file_env DB_ROOT_PASSWORD
file_env DB_USER
file_env DB_NAME

# subscript help
_sub_usage(){
	cat >> /dev/stderr <<-EOF
	usage: ${_script_exec_helpname}

	Help for the subscript
	EOF
}

# Input the command to execute in a _main() function
_main(){
	_setup_pgpass
	log_inf psql "${@}"
	#psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} "${@}"
	psql "${@}"
}

if echo $*|grep -qwe "-help\|--help"; then
	_sub_usage
	exit
fi

_main "${@}"

#END
