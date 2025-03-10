#!/bin/bash

echo "# --- --- --- --- --- script ---> $(readlink -f ${0})"

source "${HOME}/.bash_aliases"

LOG_FILE="${LOG_DIR}/build-synApps.log"

export SYNAPPS="${APP_ROOT}/synApps"
export SUPPORT="${SYNAPPS}/support"
export PATH="${PATH}:${SUPPORT}/utils"
export IOCS_DIR="$(readlink -m ${SUPPORT}/../iocs)"
mkdir -p "${IOCS_DIR}"

export CAPUTRECORDER_HASH=master  # https://github.com/epics-modules/motor/issues/91

echo "# ................................ update ~/bash_aliases" 2>&1 | tee -a "${LOG_FILE}"
cat >> "${HOME}/.bash_aliases"  << EOF
#
# epics_synapps.sh
export SYNAPPS="${SYNAPPS}"
export SUPPORT="${SUPPORT}"
export IOCS_DIR="${IOCS_DIR}"
export PATH="${PATH}"
export CAPUTRECORDER_HASH="${CAPUTRECORDER_HASH}"
export MOTOR_HASH="${MOTOR_HASH}"
EOF

source "${HOME}/.bash_aliases"

cd ${APP_ROOT}
echo "# ................................ download EPICS assemble_synApps.sh" 2>&1 | tee -a "${LOG_FILE}"

# download the installer script
# ENV HASH=master
export HASH=$SYNAPPS_HASH
wget \
    -q \
    --no-check-certificate \
    "https://raw.githubusercontent.com/EPICS-synApps/support/${HASH}/assemble_synApps.sh"

echo "# ................................ edit assemble_synApps.sh installer" 2>&1 | tee -a "${LOG_FILE}"
bash \
    "${RESOURCES}/edit_assemble_synApps.sh" 2>&1 \
    | tee "${LOG_DIR}/edit_assemble_synApps.log"


echo "# ................................ run assemble_synApps.sh installer" 2>&1 | tee -a "${LOG_FILE}"
# cat "${APP_ROOT}/assemble_synApps.sh"
export SYNAPPS_DIR="${SYNAPPS}"
bash \
    "${APP_ROOT}/assemble_synApps.sh" 2>&1 \
    | tee "${LOG_DIR}/assemble_synApps.log"

echo "# ................................ update ~/bash_aliases" 2>&1 | tee -a "${LOG_FILE}"
cd "${SUPPORT}"
export AD="${SUPPORT}/$(ls | grep areaDetector)"
export ASYN="${SUPPORT}/$(ls | grep asyn)"
export MOTOR="${SUPPORT}/$(ls | grep motor)"
export OPTICS="${SUPPORT}/$(ls ${SUPPORT} | grep optics)"
export XXX="${SUPPORT}/$(ls | grep xxx)"
export IOCXXX=${XXX}/iocBoot/iocxxx

cat >> "${HOME}/.bash_aliases"  << EOF
export AD="${AD}"
export ASYN="${ASYN}"
export IOCXXX="${IOCXXX}"
export MOTOR="${MOTOR}"
export OPTICS="${OPTICS}"
export XXX="${XXX}"
EOF
source "${HOME}/.bash_aliases"

echo "# ................................ build synApps" 2>&1 | tee -a "${LOG_FILE}"
CPUs=$(grep "^cpu cores" /proc/cpuinfo | uniq | awk '{print $4}')
echo "TIRPC=YES" > "${ASYN}/configure/CONFIG_SITE.local"
make -j${CPUs} -C "${SUPPORT}" release rebuild 2>&1 | tee ${LOG_DIR}/build-synApps.log

cd "${SUPPORT}"
ln -s "${SUPPORT}" /home/support


echo "# ................................ collect screen files" 2>&1 | tee -a "${LOG_FILE}"
export SCREENS="${SUPPORT}/screens"
"${RESOURCES}/copy_screens.sh" "${SUPPORT}" "${SCREENS}/"
"${RESOURCES}/modify_adl_in_ui_files.sh"  "${SCREENS}/ui"


echo "# ................................ build synApps XXX" 2>&1 | tee -a "${LOG_FILE}"
echo "# --- Building XXX IOC ---" 2>&1 | tee -a ${LOG_DIR}/build-synApps.log
make -C ${IOCXXX}/ 2>&1 | tee -a ${LOG_DIR}/build-synApps.log
ln -s ${IOCXXX}/ ./iocxxx
