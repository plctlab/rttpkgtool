#!/bin/bash
# This tool is used to copy the image files to the SD card.

function usage() {
        echo "Usage:"
        echo "  [SRC=<path_src>] [DEST=<path_dest>] ./mksd.sh [-h]"
        echo "  - SRC: path of input file, default as"
        echo "         '\${SDK_BUILD_IMAGES_DIR}/opensbi/opensbi_rtt_system.bin' if not provided"
        echo "  - DEST: path of output file, default as '/dev/sdb' if not provided"
        echo "  - -h: display usage, other options are ignored"
}

DPT_PATH=$(realpath $(dirname $0)/..)

source ${DPT_PATH}/.config

if [ "$1" = "-h" ]; then
	usage
        exit 0
fi

if [ -z "${SRC}" ]; then
	SRC=${DPT_PATH}/output/${CONFIG_BOARD_CONFIG_NAME}/images/opensbi/opensbi_rtt_system.bin
fi

if [ -z "${DEST}" ]; then
        DEST=/dev/sdb
fi

echo "SRC:  $SRC"
echo "DEST: $DEST"

if [ ! -f "${SRC}" ]; then
	echo "ERROR: The input file '${SRC}' does not exist. Please check again!"
	usage
	exit 1
fi
if [ ! -b "${DEST}" ]; then
	echo "ERROR: The output file '${DEST}' does not exist. Please check again!"
	usage
	exit 1
fi

sudo dd if=${SRC} of=${DEST} seek=20480

echo "Done!"
