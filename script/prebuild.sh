#!/bin/bash
# This tool is used to build prebuild binaries with duo-buildroot-sdk
# (https://github.com/milkv-duo/duo-buildroot-sdk.git).
# Note: Downloading of the duo-buildroot-sdk repository is not handled by
# this tool. Before running this tool, users should download the
# duo-buildroot-sdk repository and check it out to the specified version by
# themselves and provide the path of the exisiting repo. as $PATH_DUO_SDK.

DPT_PATH=$(realpath $(dirname $0)/..)
PATH_DUO_PKGTOOL=$DPT_PATH
echo "PATH_DUO_PKGTOOL = $PATH_DUO_PKGTOOL"

DEFAULT_BRANCH=develop
WORKING_BRANCH=rttpkgtool-prebuild

source ${DPT_PATH}/script/board_types.sh

declare -A mapping_boardtype2config
mapping_boardtype2config=([duo]=cv1800b_milkv_duo_sd \
			  [duo256m]=cv1812cp_milkv_duo256m_sd \
			  [duos]=cv1813h_milkv_duos_sd)

function usage() {
        echo "Usage:"
	echo "  Run following command in the rttpkgtool directory."
        echo "  PATH_DUO_SDK=<path_duo_sdk> ./prebuild.sh [-h]"
	echo "  path_duo_sdk: the full path of the existing duo-buildroot-sdk repository. e.g. $HOME/duo-buildroot-sdk"
        echo "  -h: display usage"
}

function clean_up() {
	git checkout $DEFAULT_BRANCH
	git branch -D $WORKING_BRANCH
}

function build_prebuilds() {
	local board_type=$1
	local board_name="milkv-$board_type-sd"
	local board_config=${mapping_boardtype2config[${board_type}]}

	echo "board_type = $board_type"
	echo "board_name = $board_name"
	echo "board_config = $board_config"

	echo "Building prebuilds for $board_name ......"
	source device/$board_name/boardconfig.sh
	source build/milkvsetup.sh
	defconfig $board_config
	clean_all
	build_fsbl
	build_kernel
}

function copy_prebuilds_common() {
	cp $PATH_DUO_SDK/fsbl/plat/cv181x/fiptool.py $PATH_DUO_PKGTOOL/prebuilt/common/fiptool.py
}

function copy_prebuilds() {
	local board_type=$1
	local board_name="milkv-$board_type-sd"
	local board_config=${mapping_boardtype2config[${board_type}]}

	local board_dtb=$PATH_DUO_SDK/ramdisk/build/$board_config/workspace/$board_config.dtb
	local board_multi_its=$PATH_DUO_SDK/ramdisk/build/$board_config/workspace/multi.its
	local board_bl2=$PATH_DUO_SDK/fsbl/build/$board_config/bl2.bin
	local board_blmacros_env=$PATH_DUO_SDK/fsbl/build/$board_config/blmacros.env
	local board_chip_conf=$PATH_DUO_SDK/fsbl/build/$board_config/chip_conf.bin
	local board_ddr_param=$PATH_DUO_SDK/fsbl/test/cv181x/ddr_param.bin
	local board_empty=$PATH_DUO_SDK/fsbl/test/empty.bin
	local board_fw_dynamic=$PATH_DUO_SDK/opensbi/build/platform/generic/firmware/fw_dynamic.bin
	local board_uboot_raw=$PATH_DUO_SDK/u-boot-2021.10/build/$board_config/u-boot-raw.bin

	cp $board_dtb $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/dtb/$board_config.dtb
	cp $board_multi_its $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/dtb/multi.its
	cp $board_bl2 $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/fsbl/bl2.bin
	cp $board_blmacros_env $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/fsbl/blmacros.env
	cp $board_chip_conf $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/fsbl/chip_conf.bin
	cp $board_ddr_param $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/fsbl/ddr_param.bin
	cp $board_empty $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/fsbl/empty.bin
	cp $board_fw_dynamic $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/opensbi/fw_dynamic.bin
	cp $board_uboot_raw $PATH_DUO_PKGTOOL/prebuilt/riscv/$board_type/uboot/u-boot-raw.bin
}

while getopts ":h" opt
do
        case $opt in
        h)
                O_HELP=y
                ;;
        ?)
                echo "There is unrecognized parameter."
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
if [ -z "$PATH_DUO_SDK" -o ! -d "${PATH_DUO_SDK}" ]; then
	echo "ERROR: You must specify 'PATH_DUO_SDK' and it should be an valid path!!"
	usage
	exit 1
fi

pushd $PATH_DUO_SDK > /dev/null

if [ `git rev-parse --is-inside-work-tree 2> /dev/null` = "true" ]; then
	echo "PATH_DUO_SDK = $PATH_DUO_SDK"
else
	echo "ERROR: PATH_DUO_SDK(\"$PATH_DUO_SDK\") is invalid. Please try again!"
	usage
	exit 1
fi

git rev-parse --verify $WORKING_BRANCH > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "ERROR: The branch $WORKING_BRANCH already exists in $PATH_DUO_SDK. Please remove it first!"
	# It's up to user to handle the removal of the branch.
	exit 1
fi

git checkout -b $WORKING_BRANCH

# Get the hash for the current commit in git ......
CURRENT_COMMIT_HASH=`git rev-parse --verify HEAD`
echo "Current commit hash is $CURRENT_COMMIT_HASH"

# Applying patches for duo-buildroot-sdk ......
git am $PATH_DUO_PKGTOOL/patches/0001-patchs-for-rttpkgtool.patch
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to apply patches. Please check the error message and try again!"
	clean_up
	exit 1
else
	echo "Patches have been applied successfully!"
fi

echo "Building prebuilds ......"
for supported_board_type in ${supported_board_types[@]};
do
	build_prebuilds $supported_board_type
done

echo "Copying prebuilds to rttpkgtool ......"
copy_prebuilds_common
for supported_board_type in ${supported_board_types[@]};
do
	copy_prebuilds $supported_board_type
done

echo "Recording the $CURRENT_COMMIT_HASH ......"
if [ -f $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt ]; then
	rm -f $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
fi
touch $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
echo "########################################################################################" >> $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
echo "This file is used to record the commit hash value corresponding to the latest prebuilds." >> $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
echo "The corresponding repository is: https://github.com/milkv-duo/duo-buildroot-sdk.git" >> $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
echo "########################################################################################" >> $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt
echo $CURRENT_COMMIT_HASH >> $PATH_DUO_PKGTOOL/prebuilt/commit_hash.txt

# Do some cleanup ......
clean_up
