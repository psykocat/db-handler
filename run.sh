#!/bin/bash

set -eu

build_image=
while [ ${#} -ne 0 ]; do
	case ${1} in
		--build)
			build_image="yes"
			;;
		*)
			args+=("${1}")
			;;
	esac
	shift
done

if [ "${build_image}" = "yes" ]; then
	docker-compose build -q
fi

. ./.env

# Create empty passfiles if absent for the image run
for passfile in ${LOCAL_DB_ROOT_PASSWORD_FILE} ${LOCAL_DB_PASSWORD_FILE}; do
	[ -s "${passfile}" ] || openssl rand -base64 32 > "${passfile}"
done
unset -- passfile

if [ ! -d "${SHARED_VOLUME_DIR}" ]; then
	mkdir -p "${SHARED_VOLUME_DIR}"
fi

docker-compose run --rm dbhandler "${args[@]}"

#END
