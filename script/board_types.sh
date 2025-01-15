# NOTE: Don't execute this script directly. It should be sourced by another script.
# Description: This script contains the supported board types and functions to
# check if a board type is supported.

supported_board_types=("duo" "duo256m" "duos")

function check_board_type() {
	local board_type=$1
	for supported_board_type in ${supported_board_types[@]};
	do
		if [ "$supported_board_type" = "$board_type" ]; then
			return 0
		fi
	done
	return 1
}

function print_supported_board_types() {
	echo "Supported board types:"
	for supported_board_type in ${supported_board_types[@]};
	do
		echo "  - $supported_board_type"
	done
}