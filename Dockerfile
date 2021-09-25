FROM ubuntu:20.04

ARG UBUNTU_VERS=20.04
ARG ARKIME_VERS=3.0.0-1_amd64
ARG SURICATA_VERSION=5.0.3

ENV TZ="America/New_York"

# ARKIME LOGIC
RUN apt-get update -y && apt-get upgrade -y &&\apt-get install -y curl wget ethtool libwww-perl libjson-perl libyaml-dev libmagic1 unzip && apt-get clean

RUN mkdir /data && cd /data && curl -C - "https://s3.amazonaws.com/files.molo.ch/builds/ubuntu-"$UBUNTU_VERS"/moloch_"$ARKIME_VERS".deb" -o arkime.deb && dpkg -i arkime.deb && rm arkime.deb
RUN /data/moloch/bin/moloch_update_geo.sh


# SURICATA LOGIC
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y apt-transport-https \
        lsb-release \
        gnupg2 \
        p7zip-full \
        vim \
        tcpdump \
        netcat \
        net-tools \
        libpcre3 \
        libpcre3-dbg \
        libpcre3-dev \
        build-essential \
        libpcap-dev \
        libnet1-dev \
        libyaml-0-2 \
        libyaml-dev \
        pkg-config \
        zlib1g \
        zlib1g-dev \
        libcap-ng-dev \
        libcap-ng0 \
        make \
        libmagic-dev \
        libjansson-dev \
        libnss3-dev \
        libgeoip-dev \
        liblua5.1-dev \
        libhiredis-dev \
        libevent-dev \
        python-yaml \
        rustc \
        cargo &&\
    apt-get update

WORKDIR /src
RUN wget https://www.openinfosecfoundation.org/download/suricata-${SURICATA_VERSION}.tar.gz &&\
    	tar zxf suricata-${SURICATA_VERSION}.tar.gz;

WORKDIR /src/suricata-${SURICATA_VERSION}

RUN ./configure \
        --disable-shared \
        --disable-gccmarch-native \
        --enable-lua \
        --prefix=/usr/ \
        --sysconfdir=/etc \
        --localstatedir=/var

RUN make &&\
    make install install-conf

COPY /suricata/suricata.rules /etc/suricata/rules/suricata.rules

RUN mkdir /arkime && cd /arkime && mkdir bin log
ADD /scripts /arkime/bin
RUN chmod 755 /arkime/bin/*.sh


ENV ARKIME_DIR "/data/moloch"
VOLUME /arkime/etc
EXPOSE 8005/tcp
