FROM  debian:stable-slim

ENV IMAGE_VERSION="2.0.2-RAF"
ENV PREFIX="ioc:"
ENV APP_ROOT="/opt"
ENV RESOURCES="${APP_ROOT}/resources"
ENV LOG_DIR="${APP_ROOT}/logs"
##EPICS
ENV EPICS_BASE_VERSION=7.0.9
##SYNAPPS
ENV SYNAPPS_HASH=R6-2-1
ENV MOTOR_HASH=R7-2-2
##

RUN DEBIAN_FRONTEND=noninteractive apt-get update  -y \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y  \
        apt-utils \
        build-essential \
        git \
        less \
        libnet-dev \
        libpcap-dev \
        libreadline-dev \
        libusb-1.0-0-dev \
        libusb-dev \
        libx11-dev \
        libxext-dev \
        procps \
        re2c \
        wget
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${RESOURCES}" "${LOG_DIR}"

COPY ./resources/ "${RESOURCES}"


RUN echo "# -------------------------------- start EPICS base" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN "${RESOURCES}/install/epics_base.sh" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN echo "# -------------------------------- end EPICS base" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"

RUN echo "# -------------------------------- start EPICS synApps" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN "${RESOURCES}/install/epics_synapps.sh" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN echo "# -------------------------------- end EPICS synApps" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"

RUN echo "# -------------------------------- start create custom GP IOC" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
COPY ./resources/gp/gp_screens/ /tmp/gp_screens
RUN "${RESOURCES}/gp/custom_gp_ioc.sh" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN echo "# -------------------------------- end create custom GP IOC" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"

RUN echo "# -------------------------------- start create custom ADSimDetector IOC" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
COPY ./resources/adsim/adsim_README /tmp/
COPY ./resources/adsim/adsim_screens/ /tmp/adsim_screens
RUN "${RESOURCES}/ad/custom_adsim_ioc.sh" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"
RUN echo "# -------------------------------- end create custom ADSimDetector IOC" 2>&1 | tee -a "${LOG_DIR}/dockerfile.log"


# # TODO: add support to start/stop IOCs in containers
