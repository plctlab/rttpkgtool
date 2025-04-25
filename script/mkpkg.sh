#!/bin/bash
# This tool is used to package the kernel, bootloader and etc. into the image file.

#set -v

DPT_PATH=$(realpath $(dirname $0)/..)

source ${DPT_PATH}/.config
source ${DPT_PATH}/script/commit_hash.txt

function usage() {
        echo "Usage:"
        echo "  DPT_PATH_KERNEL=<path_kernel> \\"
	echo "  [DPT_PATH_OUTPUT=<path_output>] \\"
	echo "  [DPT_CROSS_COMPILE=<path_toolchain>] \\"
	echo "  ./mkpkg.sh [-h] [-f]"
	echo "  DPT_PATH_KERNEL: where the rtthread.bin is located, must be specified"
	echo "  DPT_PATH_OUTPUT: where the output root directory is. Default is"
	echo "                   \rttpkgtool/output' if not provided."
	echo "  DPT_CROSS_COMPILE: the whole prefix of toolchain, Default is"
	echo "                     '/opt/toolchain/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1/bin/riscv64-unknown-linux-gnu-'"
	echo "                     if not provided."
        echo "  -h: display usage, other options are ignored"
	echo "  -f: clean and rebuild the package"
}

function download_opensbi()
{
	local project_path=$1/opensbi
	local target_version=$2
	local working_branch=branch-${target_version}
	local url_opensbi="https://gitee.com/canmv-k230/opensbi.git"

	echo "Trying to download the opensbi source code ......"
	if [ ! -d ${project_path} ]; then
		echo "${project_path} does not exist, clone it from ${url_opensbi}"
		git clone ${url_opensbi} ${project_path}

		if [ $? -ne 0 ]; then
			echo "Failed to clone ${url_opensbi} !"
			exit 1
		fi

		pushd ${project_path}
	else
		echo "${project_path} already exists."
		pushd ${project_path}
		git checkout canmv_k230
		git pull
	fi

	# For both cases:
	
	# delete the branch with the same name if any and no error reported
	git branch -D $working_branch &>/dev/null
	git checkout $target_version -b $working_branch
	popd
}

while getopts ":hf" opt
do
        case $opt in
        h)
                O_HELP=y
                ;;
	f)
		O_FORCE=y
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
if [ ! -f "${DPT_PATH_KERNEL}/rtthread.bin" ]; then
	echo "ERROR: The rtthread.bin does not exist. Please check again!"
	usage
	exit 1
fi

if [ -z "$DPT_PATH_OUTPUT" ]; then
	DPT_PATH_OUTPUT=${DPT_PATH}/output
fi

if [ -z "$DPT_CROSS_COMPILE" ]; then
	DPT_CROSS_COMPILE="/opt/toolchain/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1/bin/riscv64-unknown-linux-gnu-"
fi
if [ ! -x "${DPT_CROSS_COMPILE}gcc" ]; then
	echo "ERROR: The toolchain does not exist, please check again!"
	usage
	exit 1
fi

export SDK_SRC_ROOT_DIR=${DPT_PATH}
export SDK_TOOLS_DIR=${SDK_SRC_ROOT_DIR}/tools
export SDK_OPENSBI_SRC_DIR=${DPT_PATH_OUTPUT}/src
export SDK_BUILD_DIR=${DPT_PATH_OUTPUT}/${CONFIG_BOARD_CONFIG_NAME}
export SDK_BUILD_IMAGES_DIR=${SDK_BUILD_DIR}/images
export SDK_OPENSBI_BUILD_DIR=${SDK_BUILD_DIR}/opensbi

printf "\n"
printf "DPT_PATH_KERNEL: '$DPT_PATH_KERNEL'\n"
printf "DPT_PATH_OUTPUT: '$DPT_PATH_OUTPUT'\n"
printf "DPT_CROSS_COMPILE: '$DPT_CROSS_COMPILE'\n"
printf "SDK_BUILD_IMAGES_DIR: '$SDK_BUILD_IMAGES_DIR'\n"
printf "SDK_OPENSBI_BUILD_DIR:  '$SDK_OPENSBI_BUILD_DIR'\n"

# Check dependencies ...
if ! command -v mkimage > /dev/null 2>&1 ; then
	echo "ERROR: mkimage is missing. Run 'apt install u-boot-tools' to install it." 
	exit 1
fi

if [ "$O_FORCE" = "y" ]; then
	rm -rf ${DPT_PATH_OUTPUT}
fi

if [ ! -d "${SDK_OPENSBI_BUILD_DIR}" ]; then
	echo "WARNING: The opensbi build directory does not exit, create it!"
	mkdir -p "${SDK_OPENSBI_BUILD_DIR}"
fi
if [ ! -d "${SDK_BUILD_IMAGES_DIR}" ]; then
	echo "WARNING: The images directory does not exit, create it!"
	mkdir -p "${SDK_BUILD_IMAGES_DIR}"
fi

if [ ! -d "${SDK_OPENSBI_SRC_DIR}" ]; then
	echo "WARNING: The opensbi source directory does not exit, create it!"
	mkdir -p "${SDK_OPENSBI_SRC_DIR}"
fi
download_opensbi ${SDK_OPENSBI_SRC_DIR} ${CURRENT_COMMIT_HASH_OPENSBI}

rm -rf ${SDK_OPENSBI_BUILD_DIR}/opensbi.bin
rm -rf ${SDK_OPENSBI_SRC_DIR}/opensbi/rtthread.bin
cp ${DPT_PATH_KERNEL}/rtthread.bin ${SDK_OPENSBI_SRC_DIR}/opensbi/
pushd ${SDK_OPENSBI_SRC_DIR}/opensbi
export PLATFORM=kendryte/fpgac908
make -j ${nproc} FW_FDT_PATH=hw.dtb FW_PAYLOAD_PATH=rtthread.bin \
     O=${SDK_OPENSBI_BUILD_DIR} OPENSBI_QUIET=1 \
     CROSS_COMPILE=${DPT_CROSS_COMPILE}
popd

cp ${SDK_OPENSBI_BUILD_DIR}/platform/kendryte/fpgac908/firmware/fw_payload.bin ${SDK_OPENSBI_BUILD_DIR}/opensbi.bin

${DPT_PATH}/script/gen_image
if [ ! -f "${SDK_BUILD_IMAGES_DIR}/opensbi/opensbi_rtt_system.bin" ]; then
	echo "ERROR: Failed to generate the image file!"
	exit 1
fi

echo "Generate the image file successfully!"
echo "The image file is located at ${SDK_BUILD_IMAGES_DIR}/opensbi/opensbi_rtt_system.bin"