#!/bin/bash
# Some packaging scripts used in rttpkgtool come directly from the
# K230 RTOS-Only SDK [1]. This script is used to illustrate how to get these
# files from the SDK with the latest version.
# Before running this tool, users should download the K230 RTOS-Only SDK
# repository and config and build the SDK, see [2].
#
# Link: https://developer.canaan-creative.com/k230_rtos/zh/dev/index.html [1]
# Link: https://developer.canaan-creative.com/k230_rtos/zh/dev/userguide/how_to_build.html [2]

PATH_RTTPKGTOOL=$(realpath $(dirname $0)/..)
echo "PATH_RTTPKGTOOL = $PATH_RTTPKGTOOL"

DEFAULT_BRANCH=for-k230
WORKING_BRANCH=rttpkgtool-prebuild

K230_RTOS_DEFAULT_CONFIG=k230_rtos_01studio_defconfig

function usage() {
        echo "Usage:"
	echo "  Run following command in the rttpkgtool directory."
        echo "  PATH_K230_RTT_SDK=<path_sdk> ./prebuild.sh [-h]"
	echo "  path_sdk: the full path of the existing K230 RTOS-Only SDK repository. e.g. $HOME/rtos_k230"
        echo "  -h: display usage"
}

function copy_prebuilds() {
	cp $PATH_K230_RTT_SDK/.config  $PATH_RTTPKGTOOL/.config
	cp $PATH_K230_RTT_SDK/include/generated/autoconf.h $PATH_RTTPKGTOOL/include/generated/autoconf.h

	cp $PATH_K230_RTT_SDK/src/opensbi/gen_image $PATH_RTTPKGTOOL/script/gen_image

	cp $PATH_K230_RTT_SDK/tools/firmware_gen.py $PATH_RTTPKGTOOL/tools/firmware_gen.py
	cp $PATH_K230_RTT_SDK/tools/gen_image_func.sh $PATH_RTTPKGTOOL/tools/gen_image_func.sh
	patch $PATH_RTTPKGTOOL/tools/gen_image_func.sh < $PATH_RTTPKGTOOL/script/gen_image_func.sh.patch
	cp $PATH_K230_RTT_SDK/tools/k230_priv_gzip $PATH_RTTPKGTOOL/tools/k230_priv_gzip
}

function record_commit_hash() {
	local commit_hash_file=$PATH_RTTPKGTOOL/script/commit_hash.txt

	pushd $PATH_K230_RTT_SDK/.repo/manifests > /dev/null
	# Get the hash for the current commit in git of manifest ......
	CURRENT_COMMIT_HASH_MANIFEST=`git rev-parse --verify HEAD`
	printf "Current commit hash of manifest:\t$CURRENT_COMMIT_HASH_MANIFEST\n"
	popd > /dev/null

	pushd $PATH_K230_RTT_SDK > /dev/null
	# Get the hash for the current commit in git of canmv_k230 ......
	CURRENT_COMMIT_HASH_CANMV_K230=`git rev-parse --verify HEAD`
	printf "Current commit hash of canmv_k230:\t$CURRENT_COMMIT_HASH_CANMV_K230\n"
	popd > /dev/null

	pushd $PATH_K230_RTT_SDK/src/opensbi/opensbi > /dev/null
	# Get the hash for the current commit in git of opensbi ......
	CURRENT_COMMIT_HASH_OPENSBI=`git rev-parse --verify HEAD`
	printf "Current commit hash of opensbi:\t\t$CURRENT_COMMIT_HASH_OPENSBI\n"
	popd > /dev/null

	echo "Recording the commit hashes ......"
	if [ -f $PATH_RTTPKGTOOL/script/commit_hash.txt ]; then
		rm -f $PATH_RTTPKGTOOL/script/commit_hash.txt
	fi
	touch $PATH_RTTPKGTOOL/script/commit_hash.txt
	echo "###########################################################################################" >> $commit_hash_file
	echo "# This file is used to record the commit hash values corresponding to the latest prebuilds." >> $commit_hash_file
	echo "###########################################################################################" >> $commit_hash_file
	echo "CURRENT_COMMIT_HASH_MANIFEST=$CURRENT_COMMIT_HASH_MANIFEST" >> $commit_hash_file
	echo "CURRENT_COMMIT_HASH_CANMV_K230=$CURRENT_COMMIT_HASH_CANMV_K230" >> $commit_hash_file
	echo "CURRENT_COMMIT_HASH_OPENSBI=$CURRENT_COMMIT_HASH_OPENSBI" >> $commit_hash_file
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
if [ -z "$PATH_K230_RTT_SDK" -o ! -d "${PATH_K230_RTT_SDK}" ]; then
	echo "ERROR: You must specify 'PATH_K230_RTT_SDK' and it should be an valid path!!"
	usage
	exit 1
fi

# Check if PATH_K230_RTT_SDK is a git repository
pushd $PATH_K230_RTT_SDK > /dev/null
if [ `git rev-parse --is-inside-work-tree 2> /dev/null` = "true" ]; then
	echo "PATH_K230_RTT_SDK = $PATH_K230_RTT_SDK"
	popd > /dev/null
else
	echo "ERROR: PATH_K230_RTT_SDK(\"$PATH_K230_RTT_SDK\") is invalid. Please try again!"
	usage
	popd > /dev/null
	exit 1
fi

# Check if rtos_k230 has been configured well
if [ ! -f $PATH_K230_RTT_SDK/.config ]; then
	echo "ERROR: The rtos_k230 has not been configured. Please run 'make xxx_defconfig' first!"
	exit 1
fi
sdk_defconfig_value=$(grep "^CONFIG_BOARD_CONFIG_NAME=" "$PATH_K230_RTT_SDK/.config" | cut -d '=' -f2)
echo "CONFIG_BOARD_CONFIG_NAME = $sdk_defconfig_value"
if [ "$sdk_defconfig_value" != "\"$K230_RTOS_DEFAULT_CONFIG\"" ]; then
	echo "ERROR: The defconfig value is not $K230_RTOS_DEFAULT_CONFIG."
	echo "Please build SDK with 'make $K230_RTOS_DEFAULT_CONFIG'!"
	exit 1
fi

# Check dependencies ...
if ! command -v patch > /dev/null 2>&1 ; then
	echo "ERROR: patch is missing. Run 'apt install patch' to install it."
	exit 1
fi

git rev-parse --verify $WORKING_BRANCH > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "ERROR: The branch $WORKING_BRANCH already exists in $PATH_RTTPKGTOOL."
	echo "Please checkout to '$DEFAULT_BRANCH' and remove '$WORKING_BRANCH' before continue!"
	# It's up to user to handle the working branch.
	exit 1
fi
git checkout -b $WORKING_BRANCH

echo "Copying prebuilds to rttpkgtool ......"
copy_prebuilds

echo "Recording commit hash of K230 RTOS-Only SDK ......"
record_commit_hash

git status
echo "Prebuild running is done, please check if any update and commit changes to rttpkgtool repo ......"
