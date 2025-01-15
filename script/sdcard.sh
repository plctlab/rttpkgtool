#!/bin/bash
# This tool is used to copy the image files to the SD card.

function usage() {
        echo "Usage:"
        echo "  [DEV=<path_dev>] ./sdcard.sh [-h] [board_type] [path_src] [path_dest]"
        echo "  - DEV: env variable, default as '/dev/sdb1' if not provided"
        echo "  - -h: display usage"
        echo "  - board_type: 'duo256m' if not provided"
        echo "  - path_src: <rttpkgtool>/output if not provided"
        echo "  - path_dest: '\${HOME}/ws/u-disk' if not provided"
}

DPT_PATH=$(realpath $(dirname $0)/..)

source ${DPT_PATH}/script/board_types.sh

if [ "$1" = "-h" ]; then
	usage
        exit 0
fi

if [ -z "$DEV" ]; then
        DEV="/dev/sdb1"
fi
BOARD_TYPE=$1
PATH_SRC=$2
PATH_DEST=$3

if [ -z "${BOARD_TYPE}" ]; then
	BOARD_TYPE="duo256m"
fi
check_board_type $BOARD_TYPE
if [ $? -ne 0 ]; then
	echo "ERROR: The board type you inputted is invalid. Please try again!"
	print_supported_board_types
	usage
	exit 1
fi

if [ -z "${PATH_SRC}" ]; then
	PATH_SRC="${DPT_PATH}/output"
fi

if [ -z "${PATH_DEST}" ]; then
        PATH_DEST="${HOME}/ws/u-disk"
fi

sudo mount ${DEV} ${PATH_DEST}
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to mount ${DEV}!"
        exit 1
fi
sudo rm -f ${PATH_DEST}/*
sudo cp ${PATH_SRC}/${BOARD_TYPE}/* ${PATH_DEST}
sudo umount ${PATH_DEST} 

