#!/bin/bash

set -eu
set -x

_files_to_remove=()
_orig_uid=
_orig_gid=

. "${DBHANDLER_SCRIPTS_DIR}/.common.sh"

usage() {
	local _bname= _sub=
	{
		echo "Usage: ${0} <subscripts> [subscript options and arguments]"
		echo ""
		echo "List of subscripts:"
		echo ""
		for _sub in ${DBHANDLER_SCRIPTS_DIR}/*.sh; do
			_bname=$(basename "${_sub}")
			_bname=${_bname%.sh}
			echo "${_bname}"
		done
		echo ""
		echo "Use <subscript> --help to see the help of the specific sub script."
		echo ""
		echo "You can also use directly a shell command instead."
	} >> /dev/stderr
}

## Rights management
preset_rights(){
	_orig_uid=$(stat -c '%u' /app)
	_orig_gid=$(stat -c '%g' /app)
	sudo chown -R dbhandler:dbhandler /app
}

cleanup(){
	local _ftr=
	for _ftr in ${_files_to_remove[@]}; do
		rm -vrf -- "${_ftr}"
	done

	sudo chown -R "${_orig_uid}:${_orig_gid}" /app
}
trap cleanup EXIT ABRT HUP

preset_rights

## Checks that at least an argument is provided
[[ $# -gt 0 ]] || { usage; exit 0; }

## Check first argument to see if it is a subscript or a binary
if ! command -v ${1:-} &>/dev/null; then
	# Add extension if missing
	_script_exec="${DBHANDLER_SCRIPTS_DIR}/${1#.sh}.sh"
	# Check that subscript exists
	[[ -s "${_script_exec}" ]] || { usage; exit 0; }
	shift
	_script_exec_helpname=$(basename ${_script_exec%.sh})
	## Restore arguments with proper script at first
	#set -- $*

	# Source the script to use common methods
	. "${_script_exec}"
else
	exec $@
fi

#END
