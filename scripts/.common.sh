#!/bin/bash

## To use the common script copy in your script the uncommented line below
#. "${DBHANDLER_SCRIPTS_DIR}/.common.sh"

__shared_dir="${DBHANDLER_BACKUP_DIR}"

# Generic and fixed timestamp for backups among others
_TS=$(date +%y%m%d-%H%M)

### Common functions to entrypoint and subscripts
# Logging functions
_log_msg(){
	local msg_type="${1}"; shift
	local msg_prio="${1}"; shift
	local msg="${@}"
	local ts=$(date '+%Y-%m-%d %H:%M:%S')
	logger -st "$(basename ${0}):${msg_type}" "[${ts}] [${msg_type}] ${msg}"
}

log_dbg() {
	_log_msg DEBUG user.debug $*
}

log_inf() {
	_log_msg INFO user.notice $*
}

log_warn() {
	_log_msg WARNING user.warn $*
	exit 1
}

log_err() {
	_log_msg ERROR user.err $*
	exit 1
}

validate_env() {
	local var="${1:-}"
	if [ -z "${var:-}" ]; then
		log_err "Provide an environment variable to validate !"
	fi
	if [ -n "${!var}" ]; then
		return
	fi
	log_err "${var} shall not be empty !"
}

## Extracted from mariadb image
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		log_err "Both $var and $fileVar are set (but are exclusive)"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Fill .pgpass file according to infos provided by environment to avoid being prompted by default for the password
# create root and user fields
_setup_pgpass(){
	local _pfile="${HOME}/.pgpass"

	## Root user shall always specify the targeted DB to use as the default voluntarily does not exists.
	cat > "${_pfile}" <<-EOF
	${DB_HOST}:${DB_PORT}:${DB_NAME}:${DB_USER}:${DB_PASSWORD}
	${DB_HOST}:${DB_PORT}:*:${DB_ROOT_USER}:${DB_ROOT_PASSWORD}
	EOF
	chmod 600 ${_pfile}
}
### END OF Common functions

#END
