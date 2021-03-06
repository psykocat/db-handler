#!/usr/bin/env bash
set -eu

. ../.env
set -a
MYSQL_DATABASE=${DB_NAME}
MYSQL_USER=${DB_USER}
MYSQL_PASSWORD_FILE=${DB_PASSWORD_FILE}
MYSQL_ROOT_PASSWORD_FILE=${DB_ROOT_PASSWORD_FILE}
POSTGRES_DB=${DB_NAME}
POSTGRES_USER=postgres
POSTGRES_PASSWORD_FILE=${DB_ROOT_PASSWORD_FILE}
COMPOSE_PROJECT_NAME=testdb
set +a
export LOCAL_DB_ROOT_PASSWORD_FILE LOCAL_DB_PASSWORD_FILE

for _pass_file in ${LOCAL_DB_PASSWORD_FILE} ${LOCAL_DB_ROOT_PASSWORD_FILE}; do
	if [ -s "${_pass_file}" ]; then
		continue
	fi
	mkdir -p $(dirname ${_pass_file})
	openssl rand -base64 32 > "${_pass_file}"
done
unset -- _pass_file

# export DBNET_NETWORK_NAME
# docker network create --scope=swarm --attachable ${DBNET_NETWORK_NAME} || echo -e "\nNetwork ${DBNET_NETWORK_NAME} already exists."

action="${1:-up}"
case "${action}" in
	up)
		docker-compose -f compose.yml up -d --force-recreate
		;;
	down)
		docker-compose -f compose.yml down
		;;
	down-volumes)
		docker-compose -f compose.yml down --volumes
		;;
	*)
		docker-compose -f compose.yml $*
		;;
esac
#END
