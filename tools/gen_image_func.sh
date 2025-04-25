#!/bin/bash

add_firmHead()
{
	local filename="$1"
	local firmware_gen="${SDK_TOOLS_DIR}/firmware_gen.py"
	if [ $# -ge 2 ]; then 
		firmArgs="$2"
		cp ${filename} ${filename}.t; 					python3  ${firmware_gen}   -i ${filename}.t -o f${firmArgs##-}${filename} ${firmArgs};
	else 
		firmArgs="-n"; cp ${filename} ${filename}.t;  	python3  ${firmware_gen}   -i ${filename}.t -o f${firmArgs##-}_${filename} ${firmArgs};

		if [ "${CONFIG_GEN_SECURITY_IMG}" = "y" ];then
			firmArgs="-s";cp ${filename} ${filename}.t;	python3  ${firmware_gen}   -i ${filename}.t -o f${firmArgs##-}_${filename} ${firmArgs};
			firmArgs="-a";cp ${filename} ${filename}.t;	python3  ${firmware_gen}   -i ${filename}.t -o f${firmArgs##-}_${filename} ${firmArgs};
		fi
	fi
	rm -rf  ${filename}.t
}

k230_gzip()
{
	local filename="$1"
	local k230_gzip_tool="${SDK_TOOLS_DIR}/k230_priv_gzip "
	${k230_gzip_tool} -n8  -f -k ${filename}  ||   ${k230_gzip_tool} -n9 -f -k ${filename} ||  \
	${k230_gzip_tool} -n7 -f -k ${filename}   ||   ${k230_gzip_tool} -n6 -f -k ${filename} || \
	${k230_gzip_tool} -n5 -f -k ${filename}   ||   ${k230_gzip_tool} -n4 -f -k ${filename}
	sed -i -e "1s/\x08/\x09/"  ${filename}.gz
}

bin_gzip_ubootHead_firmHead()
{
	local mkimage="mkimage"
	local file_full_path="$1"
	local filename=$(basename ${file_full_path})
	local mkimgArgs="$2"
	local firmArgs="$3"

	[ "$(dirname ${file_full_path})" == "$(pwd)" ] || cp ${file_full_path} .

	k230_gzip ${filename}

	${mkimage} -A riscv -C gzip ${mkimgArgs} -d ${filename}.gz ug_${filename}

	add_firmHead ug_${filename}
	rm -rf ${filename} ${filename}.gz ug_${filename}
}

