#!/bin/bash

file_env DB_USER
file_env DB_PASSWORD
file_env DB_ROOT_USER
file_env DB_ROOT_PASSWORD
file_env DB_NAME

__user_action="add"
__remove_db=""

__database_extensions=()

# subscript help
_sub_usage(){
	cat >> /dev/stderr <<-EOF
	usage: ${_script_exec_helpname} [--add-user|--delete-user] [--remove-db] [--add-extension ext_name] [user_tmpl...]

	Manage user in the given database:
	--add-user / --delete-user : Handle whether you want to add or remove a user. Default is to add
	--remove-db : remove the database (should be used separately or along the user suppression.
	--add-extension : Add postgresql extension to database, can be used multiple times.

	user_tmpl : template of user to add/remove. If nothing is provided the default user/password/db are retrieved from the environment variables.
	            Otherwise use the following template : username:password[:dbname]
	EOF
}

_create_db(){
	local _dbname="${1}"

	log_inf "Create database '${_dbname}' if not already existing"
	# Use default database postgres as reference for logging
	echo "SELECT 'CREATE DATABASE ${_dbname}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${_dbname}')\gexec" | psql -U ${DB_ROOT_USER} -h ${DB_HOST} postgres
}

_delete_db(){
	local _dbname="${1}"

	log_inf "Delete database '${_dbname}' if existing"
	# Use default database postgres as reference for logging
	echo "DROP DATABASE IF EXISTS ${_dbname}\gexec" | psql -U "${DB_ROOT_USER}" -h "${DB_HOST}" postgres
}

_add_db_extension(){
	local _ext="${1}"

	log_inf "Enable '${_ext}' extension if not already existing"
	# Use default database postgres as reference for logging
	echo "CREATE EXTENSION IF NOT EXISTS ${_ext}\gexec" | psql -U "${DB_ROOT_USER}" -h "${DB_HOST}" postgres
}

_create_user(){
	local _dbuser="${1}"
	local _dbpass="${2}"
	local _dbname="${3}"

	log_inf "Create user associated to database"
	local _pgs="/tmp/user_update_script.sql"
	_files_to_remove+=("${_pgs}")

	cat > "${_pgs}" <<-EOF
	CREATE USER ${_dbuser} WITH ENCRYPTED PASSWORD '${_dbpass}';
	GRANT ALL PRIVILEGES ON DATABASE ${_dbname} TO ${_dbuser};
	EOF
	psql -U "${DB_ROOT_USER}" -h "${DB_HOST}" postgres -f "${_pgs}"
}

_delete_user(){
	local _dbuser="${1}"

	local _pgs="/tmp/usermanagement.sql"
	_files_to_remove+=("${_pgs}")

	log_inf "Remove user '${_dbuser}'"
	cat > "${_pgs}" <<-EOF
	DROP USER ${_dbuser};
	EOF
	psql -U "${DB_ROOT_USER}" -h "${DB_HOST}" postgres -f "${_pgs}"
}

_process_field_user(){
	# shall match user:password[:dbname]
	local _tmpl="${1}" _dbuser= _dbpass= _dbname=

	_dbuser=$(echo "${_tmpl}"|cut -d':' -f1)
	_dbpass=$(echo "${_tmpl}"|cut -d':' -f2)
	_dbname=$(echo "${_tmpl}"|cut -d':' -f3)

	log_inf "Processing : ${_dbuser} / ${_dbpass} / ${_dbname}"
	if [ -z "${_dbname}" ]; then
		_dbname="${DB_NAME}"
	fi

	if [ "${__remove_db}" = "yes" ]; then
		_delete_db "${_dbname}"
	fi

	if [ "${__user_action}" = "add" ]; then
		_create_db "${_dbname}"
		_create_user "${_dbuser}" "${_dbpass}" "${_dbname}"
	elif [ "${__user_action}" = "delete" ]; then
		_delete_user "${_dbuser}"
	fi

}

# Input the command to execute in a _main() function
_main(){
	local _args=() _tmpl= _ext=
	_setup_pgpass

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
			--add-user)
				__user_action="add"
				;;
			--delete-user)
				__user_action="delete"
				;;
			--remove-db)
				__remove_db="yes"
				;;
			--add-extension)
				shift;
				__database_extensions+=("${1}")
				;;
			*) _args+=("${1}");;
		esac
		shift
	done
	if [ ${#_args[@]} -eq 0 ]; then
		_args+=( "${DB_USER}:${DB_PASSWORD}:${DB_NAME}" )
	fi
	for _tmpl in ${_args[@]}; do
		_process_field_user ${_tmpl}
	done

	if [ "${__user_action}" = "add" ]; then
		for _ext in ${__database_extensions[@]}; do
			_add_db_extension "${_ext}"
		done
	fi
}

_main "${@}"

#END
