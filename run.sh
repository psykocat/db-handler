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

# Create empty passfiles if absent for the image run
for passfile in ./db_password ./db_root_password; do
	[ -s "${passfile}" ] || echo "empty" > "${passfile}"
done
unset -- passfile

docker-compose run --rm dbhandler "${args[@]}"

#END
