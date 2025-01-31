#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
#B='\033[0;34m'
M='\033[0;35m'
GRAY='\033[0;90m'
E='\033[0m'

TAG=v3.0.6
SRC=$(dirname $(realpath $0))
MULTI_USERS=NO

if [ $# -ne 1 ]; then
    echo "Usage: $0 <BOARD>"
    exit 1
else
    case "${1}" in
        "vkrzv2l")
            FML="v2l"
            PKG1=oss_pkg_rzv_${TAG}.7z
            PKG2=RTK0EF0045Z0024AZJ-${TAG}.zip
            PKG3=r01an7254ej0210-rzv-multi-os-pkg.zip
            PKG4=RTK0EF0045Z13001ZJ-v1.2.2_EN.zip
            PKG_4=RTK0EF0045Z14001ZJ-v1.2.2_rzv_EN.zip
            PKG5=RTK0EF0045Z15001ZJ-v1.2.2_EN.zip
            PKG_5=RTK0EF0045Z16001ZJ-v1.2.2_rzv_EN.zip
            PKG6=r11an0549ej0750-rzv2l-drpai-sp.zip
            PKG7=r11an0845ej0110-rzv2l-opencv-accelerator-sp.zip
        ;;
        "vkrzg2l" | "vkrzg2lc" | "vkrzg2ul" | "vkcmg2lc" | "vk-d184280e")
            FML="g2l"
            PKG1=oss_pkg_rzg_${TAG}.7z
            PKG2=RTK0EF0045Z0021AZJ-${TAG}-update3.zip
            PKG3=r01an5869ej0210-rzg-multi-os-pkg.zip
            PKG4=RTK0EF0045Z13001ZJ-v1.2.2_EN.zip
            PKG_4=RTK0EF0045Z14001ZJ-v1.2.2_rzg_EN.zip
            PKG5=RTK0EF0045Z15001ZJ-v1.2.2_EN.zip
            PKG_5=RTK0EF0045Z16001ZJ-v1.2.2_rzg_EN.zip
        ;;
        *)
            echo -e "Unsupported BOARD: ${R}${1}${E}"
            echo -e "Available BOARDs are: ${G}vkrzv2l${E} | ${G}vkrzg2l${E} | ${G}vkrzg2lc${E} | ${G}vkrzg2ul${E} | ${G}vkcmg2lc${E} | ${G}vk-d184280e${E}"
            exit 1 
        ;;
    esac
    BRD=${1}
    echo -e "\nBuilding ${M}Yocto${E} for ${G}${BRD}${E} board\n"
fi

if ! command -v wget &> /dev/null; then
    echo -e "Checking for ${Y}wget${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}wget${E} ..."
    echo -e "  ${Y}-------------------${E}"
    sudo apt-get install wget -y
    echo -e "  ${Y}-------------------${E}"
    if command -v wget &> /dev/null; then
        echo -e "  Nice! Now you have ${G}wget${E}"
    else
        echo -e "  Something got wrong! Please install ${R}wget${E} manually"
        exit 1
    fi
else
    echo -e "Checking for ${Y}wget${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if ! command -v 7z &> /dev/null; then
    echo -e "Checking for ${Y}7z${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}7z${E} ..."
    echo -e "  ${Y}-------------------${E}"
    sudo apt-get install p7zip-full -y
    echo -e "  ${Y}-------------------${E}"
    if command -v 7z &> /dev/null; then
        echo -e "  Nice! Now you have ${G}7z${E}"
    else
        echo -e "  Something got wrong! Please install ${R}7z${E} manually"
        exit 1
    fi
else
    echo -e "Checking for ${Y}7z${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if ! command -v unzip &> /dev/null; then
    echo -e "Checking for ${Y}unzip${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}unzip${E} ..."
    echo -e "  ${Y}-------------------${E}"
    sudo apt-get install unzip -y
    echo -e "  ${Y}-------------------${E}"
    if command -v unzip &> /dev/null; then
        echo -e "  Nice! Now you have ${G}unzip${E}"
    else
        echo -e "  Something got wrong! Please install ${R}unzip${E} manually"
        exit 1
    fi
else
    echo -e "Checking for ${Y}unzip${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if ! command -v curl &> /dev/null; then
    echo -e "Checking for ${Y}curl${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}curl${E} ..."
    echo -e "  ${Y}-------------------${E}"
    sudo apt-get install curl -y
    echo -e "  ${Y}-------------------${E}"
    if command -v curl &> /dev/null; then
        echo -e "  Nice! Now you have ${G}curl${E}"
    else
        echo -e "  Something got wrong! Please install ${R}curl${E} manually"
        exit 1
    fi
else
    echo -e "Checking for ${Y}curl${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if ! command -v docker &> /dev/null; then
    echo -e "Checking for ${Y}docker${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}docker${E} ..."
    echo -e "  ${Y}-------------------${E}"
    sudo apt-get update
    sudo apt-get install ca-certificates -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    echo -e "  ${Y}-------------------${E}"
    sudo usermod -aG docker ${USER}
    echo "  Trying docker ..."
    if su - "${USER}" -c 'docker run hello-world | grep "^Hello from Docker!$"'; then
        echo -e "  Nice! Now you have ${G}docker${E}"
        echo -e "  Please log out (typing ${R}exit${E}) & log in, after that, run the ${G}${0}${E} script again, so the group changes to take effect."
        exit 0
    else
        echo -e "  Something got wrong! Please install ${R}docker${E} manually & investigate why hello-world ${R}doesn't${E} work!"
        exit 1
    fi
else
    echo -e "Checking for ${Y}docker${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^rz_ubuntu-20.04:"; then
    echo -e "Checking for ${Y}Yocto docker IMG${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "  Installing ${M}Yocto docker IMG${E} ... ${G}rz_ubuntu-20.04${E}"
    echo -e "  ${Y}-------------------${E}"
    if [ "${MULTI_USERS}" = "YES" ]; then
        docker build --no-cache --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(getent group docker | cut -d: -f3)" --build-arg "USERNAME=yocto" --build-arg "TZ_VALUE=$(cat /etc/timezone)" --tag rz_ubuntu-20.04 --file ${SRC}/Dockerfile.vkrz_ubuntu-20.04 .
    else
        docker build --no-cache --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" --build-arg "USERNAME=yocto" --build-arg "TZ_VALUE=$(cat /etc/timezone)" --tag rz_ubuntu-20.04 --file ${SRC}/Dockerfile.vkrz_ubuntu-20.04 .
    fi
    echo -e "  ${Y}-------------------${E}"
    if docker images | grep -q "^rz_ubuntu-20.04"; then
        echo -e "  Nice! Now you have ${G}rz_ubuntu-20.04${E} docker IMG"
    else
        echo -e "  Something got wrong! Please build ${R}docker IMG${E} manually, following the ${G}https://github.com/renesas-rz/docker_setup${E} guide!"
        exit 1
    fi
else
    echo -e "Checking for ${Y}Yocto docker IMG${E} ... ${G}YES${E} ${Y}(rz_ubuntu-20.04)${E} ${GRAY}[INSTALLED]${E}"
fi

if [ ! -d "${SRC}/rz${FML:0:1}_vlp_${TAG}" ]; then
    echo -e "\nCreating ${Y}package${E} dir ..."
    mkdir -p ${SRC}/rz${FML:0:1}_vlp_${TAG}
fi
echo -e "\nChecking ${Y}packages${E} ... for ${G}${FML^^}${E} Family"

if [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG1}" ]; then
    echo -e "  Checking for package ${M}${PKG1}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "    Downloading ... ${R}${PKG1}${E}"
    if ! wget -O ${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG1} https://www.renesas.com/us/en/document/swo/open-source-packagesosspkgrz${FML:0:1}${TAG//./}7z; then
        echo -e "    Please download ${R}${PKG1}${E} in ${GRAY}${SRC}/${G}rz${FML:0:1}_vlp_${TAG}${E} folder & run ${G}${0}${E} script again!"
        echo    "     _______________/\______________________________"
        echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG1}${E}"
        echo -e "    \`-----------------------------------------------\`\n"
        exit 1
    fi
else
    echo -e "  Checking for package ${M}${PKG1}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG2}" ]; then
    echo -e "  Checking for package ${M}${PKG2}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "    Please download ${R}${PKG2}${E} in ${GRAY}${SRC}/${G}rz${FML:0:1}_vlp_${TAG}${E} folder through your ${R}renesas${E} account & run ${G}${0}${E} script again!"
    echo    "     _______________/\______________________________"
    echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG2}${E}"
    echo -e "    \`-----------------------------------------------\`\n"
    exit 1
else
    echo -e "  Checking for package ${M}${PKG2}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG3}" ]; then
    echo -e "  Checking for package ${M}${PKG3}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "    Downloading ... ${R}${PKG3}${E}"
    if ! wget -O ${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG3} https://www.renesas.com/en/document/sws/rz${FML:0:1}-multi-os-package-v210; then
        echo -e "    Please download ${R}${PKG3}${E} in ${GRAY}${SRC}/${G}rz${FML:0:1}_vlp_${TAG}${E} folder & run ${G}${0}${E} script again!"
        echo    "     _______________/\______________________________"
        echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG3}${E}"
        echo -e "    \`-----------------------------------------------\`\n"
        exit 1
    fi
else
    echo -e "  Checking for package ${M}${PKG3}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
fi

if [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG4}" ] && [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG_4}" ]; then
    echo -e "  Checking for package ${M}${PKG4}${E}${GRAY}/${PKG_4}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "    Please download ${R}${PKG4}${E} in ${GRAY}${SRC}/${G}rz${FML:0:1}_vlp_${TAG}${E} folder through your ${R}renesas${E} account & run ${G}${0}${E} script again!"
    echo    "     _______________/\______________________________"
    echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG4}${E}"
    echo -e "    \`-----------------------------------------------\`\n"
    exit 1
else
    if [ -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG_4}" ]; then
        echo -e "  Checking for package ${M}${PKG_4}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    else
        echo -e "  Checking for package ${M}${PKG4}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    fi
fi

if [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG5}" ] && [ ! -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG_5}" ]; then
    echo -e "  Checking for package ${M}${PKG5}${E}${GRAY}/${PKG_5}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
    echo -e "    Please download ${R}${PKG5}${E} in ${GRAY}${SRC}/${G}rz${FML:0:1}_vlp_${TAG}${E} folder through your ${R}renesas${E} account & run ${G}${0}${E} script again!"
    echo    "     _______________/\______________________________"
    echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG5}${E}"
    echo -e "    \`-----------------------------------------------\`\n"
    exit 1
else
    if [ -f "${SRC}/rz${FML:0:1}_vlp_${TAG}/${PKG_5}" ]; then
        echo -e "  Checking for package ${M}${PKG_5}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    else
        echo -e "  Checking for package ${M}${PKG5}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    fi
fi

if [ "${FML}" = "v2l" ]; then
    if [ ! -f "${SRC}/rzv_vlp_${TAG}/${PKG6}" ]; then
        echo -e "  Checking for package ${M}${PKG6}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
        echo -e "    Please download ${R}${PKG6}${E} in ${GRAY}${SRC}/${G}rzv_vlp_${TAG}${E} folder through your ${R}renesas${E} account & run ${G}${0}${E} script again!"
        echo    "     _______________/\______________________________"
        echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG6}${E}"
        echo -e "    \`-----------------------------------------------\`\n"
        exit 1
    else
        echo -e "  Checking for package ${M}${PKG6}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    fi

    if [ ! -f "${SRC}/rzv_vlp_${TAG}/${PKG7}" ]; then
        echo -e "  Checking for package ${M}${PKG7}${E} ... ${R}NO${E} ${GRAY}[MISSING]${E}"
        echo -e "    Please download ${R}${PKG7}${E} in ${GRAY}${SRC}/${G}rzv_vlp_${TAG}${E} folder through your ${R}renesas${E} account & run ${G}${0}${E} script again!"
        echo    "     _______________/\______________________________"
        echo -e "    | https://www.renesas.com/us/en/search?keywords=${R}${PKG7}${E}"
        echo -e "    \`-----------------------------------------------\`\n"
        exit 1
    else
        echo -e "  Checking for package ${M}${PKG7}${E} ... ${G}YES${E} ${GRAY}[INSTALLED]${E}"
    fi
fi

echo -e "All packages ${G}collected${E} !"

if [ ! -d "${SRC}/vlp_${TAG}/yocto" ]; then
    echo -e "\nCreating ${Y}yocto${E} dir ..."
    mkdir -p ${SRC}/vlp_${TAG}/yocto
    echo "Getting Helper utils ..."
    cp -a ${SRC}/create_yocto_src.sh ${SRC}/run_docker ${SRC}/vlp_${TAG}/yocto/
    chmod +x ${SRC}/vlp_${TAG}/yocto/create_yocto_src.sh ${SRC}/vlp_${TAG}/yocto/run_docker
fi

if [ ! -d "${SRC}/vlp_${TAG}/yocto/${TAG}-${FML}" ]; then
    echo -e "Preparing yocto's ${M}recipes${E} ... for ${G}${FML^^}${E} Family"
    cd ${SRC}/vlp_${TAG}/yocto
    ./create_yocto_src.sh ${BRD}
    cd ${OLDPWD}
    if [ "${MULTI_USERS}" = "YES" ]; then
        chown -R :docker ${SRC}/vlp_${TAG}/yocto
        chmod -R g+rw ${SRC}/vlp_${TAG}/yocto
        find ${SRC}/vlp_${TAG}/yocto -type d -exec chmod g+s {} \;
    fi
fi

if [ -d "${SRC}/vlp_${TAG}/yocto/${TAG}-${FML}" ]; then
    echo -e "\nBuilding ...\n"
    if [ ! -d "${SRC}/vlp_${TAG}/yocto/${TAG}-${FML}/${BRD}" ]; then
        echo -e "Creating yocto's ${M}build${E} dir ... for ${G}${BRD}${E} board\n"
        mkdir -p ${SRC}/vlp_${TAG}/yocto/${TAG}-${FML}/${BRD}
    fi
    cd ${SRC}/vlp_${TAG}/yocto
    if [ "${MULTI_USERS}" = "YES" ]; then
        SETUP="umask 0002 && cd ${TAG}-${FML} && TEMPLATECONF=\$PWD/meta-vkboards/meta-vk${FML}/docs/template/conf && source poky/oe-init-build-env ${BRD}"
    else
        SETUP="cd ${TAG}-${FML} && TEMPLATECONF=\$PWD/meta-vkboards/meta-vk${FML}/docs/template/conf && source poky/oe-init-build-env ${BRD}"
    fi
    HELP="\nUse:\n  bitbake-layers add-layer ../meta-${G}xxx${E}                                  to add features\n  MACHINE=${M}${BRD}${E} bitbake core-image-${R}<${G}minimal${E}|${G}bsp${E}|${G}weston${E}|${G}qt${R}>${E}\t\tto build img\n  MACHINE=${M}${BRD}${E} bitbake core-image-${R}<${G}weston${E}|${G}qt${R}>${E} -c populate_sdk\tto build sdk\n"
    ./run_docker "${SETUP}" "${HELP}"
    cd ${OLDPWD}
else
    echo -e "No Yocto src dir: ${GRAY}${SRC}/vlp_${TAG}/yocto/${R}${TAG}-${FML}${E}"
fi

