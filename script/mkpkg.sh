#!/bin/bash
# This tool is used to package the kernel, bootloader and etc. into the image file.

#set -v

DPT_PATH=$(realpath $(dirname $0)/..)

source ${DPT_PATH}/script/board_types.sh

function usage() {
        echo "Usage:"
        echo "  DPT_PATH_KERNEL=<path_kernel> [DPT_BOARD_TYPE=<board_type>] [DPT_PATH_OUTPUT=<path_output>] ./mkpkg.sh [-h|-l|-b|-a]"
        echo "  -h: display usage"
        echo "  -l: make little"
        echo "  -b: make big"
        echo "  -a: make all (both big and little)"
}

function package_little() {
	local PATH_KERNEL="${DPT_PATH_KERNEL}/bsp/cvitek/c906_little/rtthread.bin"

	if [[ ! -f "${PATH_KERNEL}" ]]; then
		echo "ERROR: ${PATH_KERNEL} does not exist!\n"
		return 1
	fi
			
	mkdir -p ${DPT_PATH_OUTPUT}/${DPT_BOARD_TYPE}

	local PATH_PREBUILT="${DPT_PATH}/prebuilt"
	local PATH_PREBUILT_COMMON="${PATH_PREBUILT}/common"
	local PATH_PREBUILT_BOARD="${PATH_PREBUILT}/${DPT_ARCH}/${DPT_BOARD_TYPE}"

	local PATH_PREBUILT_FSBL="${PATH_PREBUILT_BOARD}/fsbl"
	local PATH_PREBUILT_OPENSBI="${PATH_PREBUILT_BOARD}/opensbi"
	local PATH_PREBUILT_UBOOT="${PATH_PREBUILT_BOARD}/uboot"

	if [ ! -x "${PATH_PREBUILT_COMMON}/fiptool.py" ]; then
		echo "WARNING: '${PATH_PREBUILT_COMMON}/fiptool.py' is not executable. Adding executable permission..."
		chmod +x "${PATH_PREBUILT_COMMON}/fiptool.py"
	fi

	source ${PATH_PREBUILT_FSBL}/blmacros.env && \
	${PATH_PREBUILT_COMMON}/fiptool.py -v genfip \
	${DPT_PATH_OUTPUT}/${DPT_BOARD_TYPE}/fip.bin \
	--MONITOR_RUNADDR="${MONITOR_RUNADDR}" \
	--BLCP_2ND_RUNADDR="${BLCP_2ND_RUNADDR}" \
	--CHIP_CONF=${PATH_PREBUILT_FSBL}/chip_conf.bin \
	--NOR_INFO='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' \
	--NAND_INFO=00000000 \
	--BL2=${PATH_PREBUILT_FSBL}/bl2.bin \
	--BLCP_IMG_RUNADDR=0x05200200 \
	--BLCP_PARAM_LOADADDR=0 \
	--BLCP=${PATH_PREBUILT_FSBL}/empty.bin \
	--DDR_PARAM=${PATH_PREBUILT_FSBL}/ddr_param.bin \
	--BLCP_2ND=${PATH_KERNEL} \
	--MONITOR=${PATH_PREBUILT_OPENSBI}/fw_dynamic.bin \
	--LOADER_2ND=${PATH_PREBUILT_UBOOT}/u-boot-raw.bin \
	--compress=lzma
}

function package_big() {
	if ! command -v mkimage > /dev/null 2>&1 ; then
		echo "ERROR: mkimage is missing. Run 'apt install u-boot-tools' to install it." 
		exit 1
	fi

	if ! command -v lzma > /dev/null 2>&1 ; then
		echo "ERROR: lzma is missing. Run 'apt install xz-utils' to install it." 
		exit 1
	fi

	if [[ $DPT_ARCH == "arm" ]]; then
		local PATH_KERNEL="${DPT_PATH_KERNEL}/bsp/cvitek/cv18xx_aarch64/Image"
	elif [[ $DPT_ARCH == "riscv" ]]; then
		local PATH_KERNEL="${DPT_PATH_KERNEL}/bsp/cvitek/cv18xx_risc-v/Image"
	fi

	local PATH_PREBUILT="${DPT_PATH}/prebuilt/${DPT_ARCH}"
	local PATH_PREBUILT_BOARD="${PATH_PREBUILT}/${DPT_BOARD_TYPE}"

	local PATH_PREBUILT_DTB="${PATH_PREBUILT_BOARD}/dtb"

	if [[ ! -f "${PATH_KERNEL}" ]]; then
		echo "ERROR: ${PATH_KERNEL} does not exist!\n"
		return 1
	fi
			
	mkdir -p ${DPT_PATH_OUTPUT}/${DPT_BOARD_TYPE}

	lzma -c -9 -f -k ${PATH_KERNEL} > ${PATH_PREBUILT_DTB}/Image.lzma
	mkimage -f ${PATH_PREBUILT_DTB}/multi.its -r ${DPT_PATH_OUTPUT}/${DPT_BOARD_TYPE}/boot.sd

	if [ -f "${PATH_PREBUILT_DTB}/Image.lzma" ]; then
		rm -rf "${PATH_PREBUILT_DTB}/Image.lzma"
	fi
}

function package_all() {
	package_little
	package_big
}

while getopts ":habl" opt
do
        case $opt in
        h)
                O_HELP=y
                ;;
        a)
                O_MAKE_ALL=y
                ;;
	b)
		O_MAKE_BIG=y
		;;
	l)
		O_MAKE_LITTLE=y
		;;
        ?)
                echo "there is unrecognized parameter."
                usage
                exit 1
                ;;
    esac
done

if [ "$O_HELP" = "y" ]; then
	usage
	exit 0
fi

# Check the input environment variables 
if [ -z "$DPT_PATH_KERNEL" ]; then
	echo "ERROR: You must specify 'DPT_PATH_KERNEL' at least, which represents the kernel directory of the RT-Thread repository!!"
	usage
	exit 1
fi
if [ ! -d "${DPT_PATH_KERNEL}" ]; then
	echo "ERROR: The kernel directory you inputted is invalid. Please try again!"
	usage
	exit 1
fi

if [ -z "$DPT_BOARD_TYPE" ]; then
	DPT_BOARD_TYPE="duo256m"
fi

if [ -z "$DPT_ARCH" ]; then
	DPT_ARCH="riscv"
fi
if [ "$DPT_ARCH" != "riscv" ] && [ "$DPT_ARCH" != "arm" ]; then
	echo "Error: the DPT_ARCH value you entered is invalid. Please enter arm or riscv. and the default DPT_ARCH=riscv."
	exit 1
fi

check_board_type $DPT_BOARD_TYPE
if [ $? -ne 0 ]; then
	echo "ERROR: The board type you inputted is invalid. Please try again!"
	print_supported_board_types
	usage
	exit 1
fi

if [ -z "$DPT_PATH_OUTPUT" ]; then
	DPT_PATH_OUTPUT="${DPT_PATH}/output"
fi
if [ ! -d "${DPT_PATH_OUTPUT}" ]; then
	echo "WARNING: The output directory you inputted does not exit, create it!"
	mkdir -p "${DPT_PATH_OUTPUT}"
fi

if [ "$O_MAKE_ALL" = "y" ]; then
	pack_config="a"
elif [ "$O_MAKE_BIG" = "y" ]; then
	pack_config="b"
elif [ "$O_MAKE_LITTLE" = "y" ]; then
	pack_config="l"
else
	pack_config="a"
fi

printf "\n"
printf "DPT_PATH_KERNEL: '$DPT_PATH_KERNEL'\n"
printf "DPT_BOARD_TYPE:  '$DPT_BOARD_TYPE'\n"
printf "DPT_PATH_OUTPUT: '$DPT_PATH_OUTPUT'\n"
printf "pack_option:     '-${pack_config}'\n\n"

case $pack_config in
	a)
		package_all
		;;
	b)
		package_big
		;;
	l)
		package_little
		;;
	*)
		package_all
		;;
esac