#!/bin/bash

VERSION=0.4.0

R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
B='\033[0;34m'
D='\033[0;90m'
E='\033[0m'

TARGET="meta-vkboards"
VKRZ_RCP_GIT_URL="https://github.com/Vekatech/${TARGET}.git"
VKRZ_RCP_BRANCH="main"
VKRZ_RCP_TAG="v3.0.6"

if [ $# -ne 1 ]; then
    echo -e "Specify a <${R}BOARD${E}> when calling ${G}$0${E}"
    echo -e "  BOARDs: [ ${G}vkrzv2l${E} | ${G}vkrzg2l${E} | ${G}vkrzg2lc${E} | ${G}vkrzg2ul${E} | ${G}vkcmg2lc${E} | ${G}vk-d184280e${E} ]"
    exit 1
fi

case "$1" in
    "vkrzv2l")
        BUILD_DIR=$1
        FAMILY="v2l"
    ;;
    "vkrzg2l" | "vkrzg2lc" | "vkrzg2ul" | "vkcmg2lc" | "vk-d184280e")
        BUILD_DIR=$1
        FAMILY="g2l"
    ;;
    *)
        echo -e "Unsupported BOARD: ${R}$1${E}"
        echo -e "Available BOARDs are: ${G}vkrzv2l${E} | ${G}vkrzg2l${E} | ${G}vkrzg2lc${E} | ${G}vkrzg2ul${E} | ${G}vkcmg2lc${E} | ${G}vk-d184280e${E}"
        exit 1 
    ;;
esac

# ----------------------------------------------------------------
WORKSPACE=$(dirname $(realpath $0))
PKGKDIR=${WORKSPACE}/../../rz${FAMILY:0:1}_vlp_${VKRZ_RCP_TAG}
YOCTO_HOME="${WORKSPACE}/${VKRZ_RCP_TAG}-${FAMILY}"
# ----------------------------------------------------------------
SUFFIX_ZIP=".zip"
SUFIX_7Z=".7z"

# Make sure that the following packages have been downloaded from the official website

case "${FAMILY}" in
    "v2l")
        TARGET_STR="RZ/V2L"

        # RZ/V Verified Linux Package [5.10-CIP]  V3.0.6
        REN_LINUX_BSP_PKG="RTK0EF0045Z0024AZJ-v3.0.6"

        # RZ MPU Graphics Library V1.2.2 Unrestricted Version
        REN_GPU_MALI_LIB_PKG="RTK0EF0045Z14001ZJ-v1.2.2_rzv_EN"
        # RZ MPU Graphics Library Evaluation Version V1.2.2
        REN_GPU_MALI_LIB_PKG_EVAL="RTK0EF0045Z13001ZJ-v1.2.2_EN"

        # RZ MPU Video Codec Library V1.2.2 Unrestricted Version
        REN_VIDEO_CODEC_LIB_PKG="RTK0EF0045Z16001ZJ-v1.2.2_rzv_EN"
        # RZ MPU Video Codec Library Evaluation Version V1.2.2
        REN_VIDEO_CODEC_LIB_PKG_EVAL="RTK0EF0045Z15001ZJ-v1.2.2_EN"

        # RZ/V2L DRP-AI Support Package Version 7.50
        REN_V2L_DRPAI_PKG="r11an0549ej0750-rzv2l-drpai-sp"

        # RZ/V2L OpenCV Accelerator Support Package V1.10
        REN_V2L_OPENCVA_PKG="r11an0845ej0110-rzv2l-opencv-accelerator-sp"

        # RZ/V2L Multi-OS Package V2.1.0
        REN_V2L_MULTI_OS_PKG="r01an7254ej0210-rzv-multi-os-pkg"
        
        OSS_PKG="oss_pkg_rzv_v3.0.6"
    ;;
    "g2l")
        TARGET_STR="RZ/G2L"

        # RZ/G Verified Linux Package [5.10-CIP]  V3.0.6
        REN_LINUX_BSP_PKG="RTK0EF0045Z0021AZJ-v3.0.6-update3"

        # RZ MPU Graphics Library V1.2.2 Unrestricted Version
        REN_GPU_MALI_LIB_PKG="RTK0EF0045Z14001ZJ-v1.2.2_rzg_EN"
        # RZ MPU Graphics Library Evaluation Version V1.2.2
        REN_GPU_MALI_LIB_PKG_EVAL="RTK0EF0045Z13001ZJ-v1.2.2_EN"

        # RZ MPU Video Codec Library V1.2.2 Unrestricted Version
        REN_VIDEO_CODEC_LIB_PKG="RTK0EF0045Z16001ZJ-v1.2.2_rzg_EN"
        # RZ MPU Video Codec Library Evaluation Version V1.2.2
        REN_VIDEO_CODEC_LIB_PKG_EVAL="RTK0EF0045Z15001ZJ-v1.2.2_EN"

        # RZ/G2L Multi-OS Package V2.1.0
        REN_G2L_MULTI_OS_PKG="r01an5869ej0210-rzg-multi-os-pkg"
        
        OSS_PKG="oss_pkg_rzg_v3.0.6"
    ;;
    *)
        echo -e "Unsupported FAMILY: ${R}${FAMILY}${E}"
        echo -e "  Available FAMILYs are: ${G}g2l${E} | ${G}v2l${E}"
        exit 1
    ;;
esac

function main_process() {
	if [ ! -d ${YOCTO_HOME} ];then
		mkdir -p ${YOCTO_HOME}
	fi

	check_pkg_require $1
        set -e
	log_info "Unpacking Renesas packages"
	unpack_bsp $1
	unpack_gpu
        unpack_codec
        if [ "$1" =  "v2l" ]; then
            unpack_drpai
            unpack_opencva
        fi
	unpack_multi_os $1
	#remove_redundant_patches
	unzip_src $1
	getrcp
        set +e
	echo ""
	echo "ls ${YOCTO_HOME}"
	ls ${YOCTO_HOME}
	echo ""
	echo "---Finished---"
}

# red
log_error(){
	local string=$1
	echo -ne "${R} $string ${E}\n"
}

# yellow
log_warn(){
	local string=$1
	echo -ne "${Y} $string ${E}\n"
}

# blue
log_info(){
	local string=$1
	echo -ne "${B} $string ${E}\n"
}

# green
log_success(){
	local string=$1
	echo -ne "${G} $string ${E}\n"
}

check_pkg_require(){
	# check required pacakages are downloaded from Renesas website
	local check=0
	cd ${PKGKDIR}

	if [ ! -e ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} Verified Linux Package' from Renesas Website"
		echo ""
		check=1
	fi
	if [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ ! -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_error "Error: Cannot found ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} MPU Graphics Library' from Renesas Website"
		echo ""
		check=2
	elif [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_warn "This is an Evaluation Version package ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP}"
		log_warn "It is recommended to download '${TARGET_STR} MPU Graphics Library Unrestricted Version' from Renesas Website"
		echo ""
	fi
        if [ ! -e ${REN_VIDEO_CODEC_LIB_PKG}${SUFFIX_ZIP} ] && [ ! -e ${REN_VIDEO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_error "Error: Cannot found ${REN_VIDEO_CODEC_LIB_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} Codec Library' from Renesas Website"
		echo ""
		check=3
	elif [ ! -e ${REN_VIDEO_CODEC_LIB_PKG}${SUFFIX_ZIP} ] && [ -e ${REN_VIDEO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_warn "This is an Evaluation Version package ${REN_VIDEO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP}"
		log_warn "It is recommended to download '${TARGET_STR} Codec Library Unrestricted Version' from Renesas Website"
		echo ""
	fi
	if [ "$1" = "v2l" ]; then	
            if [ ! -e ${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot find ${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} DRP-AI Support Package' from Renesas Website"
		echo ""
		check=4
	    fi
            if [ ! -e ${REN_V2L_OPENCVA_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot find ${REN_V2L_OPENCVA_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} OpenCV Accelerator Support Package' from Renesas Website"
		echo ""
		check=5
	    fi
	    if [ ! -e ${REN_V2L_MULTI_OS_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot find ${REN_V2L_MULTI_OS_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} Group Multi-OS Package' from Renesas Website"
		echo ""
		check=6
	    fi
	else
	    if [ ! -e ${REN_G2L_MULTI_OS_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot find ${REN_G2L_MULTI_OS_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} Group Multi-OS Package' from Renesas Website"
		echo ""
		check=4
	    fi
	fi

	[ ${check} -ne 0 ] && echo "---Failed---" && exit

        log_info  "Required Renesas packages are downloaded"
}

# usage: extract_to_meta zipfile zipdir tarfile tardir
function extract_to_meta(){
	local zipfile=$1
	local zipdir=$2
    echo "DEBUG: zipdir=$zipdir"
	local tarfile_tmp=$3
	local tardir=$4
	local tarfile=

	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!display zipfile, zipdir !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ."
	echo $zipfile $zipdir
	echo "tarfile_tmp $tardir ."
	echo $tarfile_tmp $tardir

	cd ${WORKSPACE}
	pwd
	echo "Extract zip file to ${zipdir} and then untar ${tarfile_tmp} file"
	unzip -d ${zipdir} ${zipfile}
	tarfile=$(find ${zipdir} -type f -name ${tarfile_tmp})

	if [ -z "${tarfile}" ]; then
		log_error "Can't find archives in ${zipdir}! Please check the package file."
		exit
	fi

	echo "!!!!!!!!!!!TARFILE: "${tarfile}
	echo "!!!!!!!!!!!TARDIR: "${tardir}
	tar -xzf ${tarfile} -C ${tardir}
	sync
}

function copy_docs(){
    local zipdir=$1
    local tardir=$2
    mkdir -p "${tardir}"
    while IFS= read -r doc
    do
        echo "Copy '${doc}' to '${tardir}'"
        cp -ar "${doc}" "${tardir}"
    done < <(find "${zipdir}" -type f -name "*.pdf")
}

function unpack_bsp(){
	local pkg_file=${PKGKDIR}/${REN_LINUX_BSP_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_LINUX_BSP"

    if [ "$1" =  "v2l" ]; then	
	local bsp="rzv*_v*.tar.gz"
	local dest=${YOCTO_HOME}/meta-renesas
    else
        local bsp="rzg*_v*.tar.gz"
        local dest=${YOCTO_HOME}
    fi
	local bsp_patch=""

	extract_to_meta "${pkg_file}" "${zip_dir}" "${bsp}" "${YOCTO_HOME}"
	copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/bsp"
	bsp_patch=$(find "${zip_dir}" -type f -name "*.patch")
	for ptch in $bsp_patch
	do
		echo "Applying patch: $ptch"
		patch -d ${dest} -p1 < ${ptch}
	done
	rm -fr ${zip_dir}
	
	if [ -f "${YOCTO_HOME}/meta-renesas/meta-rz-common/include/core-image-renesas-base.inc" ]; then
		sed -i "s|BSP_VERSION=\".*\"|BSP_VERSION=\"${REN_LINUX_BSP_PKG#*-v}\"|g" ${YOCTO_HOME}/meta-renesas/meta-rz-common/include/core-image-renesas-base.inc
	fi
}

function unpack_gpu(){
	local pkg_file=${PKGKDIR}/${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_GPU_MALI"
	local gpu="meta-rz*.tar.gz"

	if [ ! -e ${PKGKDIR}/${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ]; then
		pkg_file=${PKGKDIR}/${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP}
	fi

	extract_to_meta "${pkg_file}" "${zip_dir}" "${gpu}" "${YOCTO_HOME}"
	copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/gpu"
	rm -fr ${zip_dir}
}

function unpack_codec(){
	local pkg_file=${PKGKDIR}/${REN_VIDEO_CODEC_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_VIDEO_CODEC"
	local codec="meta-rz*.tar.gz"

	if [ ! -e ${PKGKDIR}/${REN_VIDEO_CODEC_LIB_PKG}${SUFFIX_ZIP} ]; then
		pkg_file=${PKGKDIR}/${REN_VIDEO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP}
	fi

	extract_to_meta "${pkg_file}" "${zip_dir}" "${codec}" "${YOCTO_HOME}"
	copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/codecs"
	rm -fr ${zip_dir}
}

function unpack_drpai(){
	local pkg_file=${PKGKDIR}/${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_V2L_DRPAI"
	local drpai="meta-rz*.tar.gz"

	extract_to_meta "${pkg_file}" "${zip_dir}" "${drpai}" "${YOCTO_HOME}"
        copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/drpai"
	rm -fr ${zip_dir}
}

function unpack_opencva(){
	local pkg_file=${PKGKDIR}/${REN_V2L_OPENCVA_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_V2L_OPENCVA"
	local opencva="meta-rz*.tar.gz"
        local opencva_patch=""

	extract_to_meta "${pkg_file}" "${zip_dir}" "${opencva}" "${YOCTO_HOME}"
        copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/opencva"
        opencva_patch=$(find "${zip_dir}" -type f -name "rzv2l-*.patch")
	for patch in $opencva_patch
	do
		echo "Applying patch: $patch"
		patch -d ${YOCTO_HOME} -p1 < ${patch}
	done
	rm -fr ${zip_dir}
}

function unpack_multi_os(){
    if [ "$1" =  "v2l" ]; then
	local pkg_file=${PKGKDIR}/${REN_V2L_MULTI_OS_PKG}${SUFFIX_ZIP}
    else
        local pkg_file=${PKGKDIR}/${REN_G2L_MULTI_OS_PKG}${SUFFIX_ZIP}
    fi
	local zip_dir="REN_MULTI_OS"
	local rtos="meta-rz*.tar.gz"

	extract_to_meta "${pkg_file}" "${zip_dir}" "${rtos}" "${YOCTO_HOME}"
        copy_docs "${zip_dir}" "${YOCTO_HOME}/docs/multi-os"
	rm -fr ${zip_dir}
}


function remove_redundant_patches(){
	# remove linux patches that were merged into the kernel
	flist=$(find "${YOCTO_HOME}" -name "linux-renesas_*.bbappend")
	for ff in ${flist}
	do
		echo "${ff}"
		rm -rf "${ff}"
	done

	# remove u-boot patches
	find "${YOCTO_HOME}" -name "u-boot_*.bbappend" -print -exec rm -rf {} \;

	# remove tfa patches
	find "${YOCTO_HOME}" -name "trusted-firmware-a.bbappend" -print -exec mv {} {}.remove \;
}

function getrcp()
{
    cd ${YOCTO_HOME}/
    #download
    git clone -b ${VKRZ_RCP_BRANCH} ${VKRZ_RCP_GIT_URL}
    if [ -n "${VKRZ_RCP_TAG}" ]; then
        cd ${TARGET}
        git checkout ${VKRZ_RCP_TAG}
        cd ..
    fi
    #ln -s ../meta-vkboards meta-vkboards
    cd ${WORKPWD}/
}

function unzip_src()
{
	if [ ! -d ${YOCTO_HOME}/${BUILD_DIR} ]; then
	   mkdir -p ${YOCTO_HOME}/${BUILD_DIR}
	fi
	7z -o${YOCTO_HOME}/../vk$1 x ${PKGKDIR}/${OSS_PKG}${SUFIX_7Z}
}

#---start--------
main_process ${FAMILY}
exit

