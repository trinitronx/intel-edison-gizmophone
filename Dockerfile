FROM balenalib/intel-edison-ubuntu-node:6-xenial-build-20181029
#FROM balenalib/intel-edison-ubuntu-node:6.17.1-cosmic-build
#FROM balenalib/intel-edison-ubuntu-node:8.17-bionic
#FROM balenalib/intel-edison-ubuntu-node:13.12-bionic

RUN install_packages python software-properties-common swig patch cmake build-essential git build-essential swig3.0 python-dev nodejs-dev cmake libjson-c-dev
RUN sudo add-apt-repository ppa:mraa/mraa && \
    sudo apt-get update

RUN install_packages libmraa1 libmraa-dev \
                     libupm1 libupm-dev \
                     mraa-tools \
                     wget rsync gnupg2 psmisc lsof tree

# This is madness... but doesn't work
# https://github.com/eclipse/mraa/blob/master/docs/building.md#javascript-bindings-for-nodejs-700
#RUN wget -O /tmp/0001-Add-Node-7.x-aka-V8-5.2-support.patch https://git.yoctoproject.org/cgit.cgi/poky/plain/meta/recipes-devtools/swig/swig/0001-Add-Node-7.x-aka-V8-5.2-support.patch && \
#    cd /usr/share/swig3.0 && \
#    patch -p2 < /tmp/0001-Add-Node-7.x-aka-V8-5.2-support.patch

#ENV MRAAVERSION v1.3.0  
#RUN git clone https://github.com/intel-iot-devkit/mraa.git && \  
#    cd mraa && \
#    git checkout -b build ${MRAAVERSION} && \
#    make install && \
#    cd .. && rm -rf mraa

# Verify & Unpack S6 Init overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-x86.tar.gz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-x86.tar.gz.sig /tmp/
RUN curl -Ls -o - https://keybase.io/justcontainers/key.asc | gpg --import && ( cd /tmp/ && gpg --trusted-key 0x2536CA16DF4FCDA2 --verify  s6-overlay-x86.tar.gz.sig  s6-overlay-x86.tar.gz ; exit $? )
RUN mkdir -p /tmp/s6-overlay-root
RUN tar -xzf /tmp/s6-overlay-x86.tar.gz -C /tmp/s6-overlay-root/

# Workaround https://github.com/just-containers/s6-overlay#bin-and-sbin-are-symlinks
RUN rsync -av --ignore-existing /tmp/s6-overlay-root/ /
COPY docker/s6-overlay-init/ /tmp/s6-etc/
RUN rsync -av --ignore-existing /tmp/s6-etc/ /etc/
# s6-fdholderd active by default
RUN s6-rmrf /etc/s6/services/s6-fdholderd/down

# Add Kernel modules for sound card: snd-usb-caiaq
# Note: This container was built to work with Traktor Audio 2 version 1
COPY kernel-modules/balena-intel-edison-2.31.5+rev1-v9.11.3-kernel-modules.tar.gz /tmp/
RUN TMPDIR=$(mktemp -d -t snd-modules.XXXXXX) && \
    tar -C $TMPDIR/ -xvf /tmp/balena-intel-edison-2.31.5+rev1-v9.11.3-kernel-modules.tar.gz && \
    rsync -av --ignore-existing $TMPDIR/ / && \
    rm -rf $TMPDIR/

# Download, compile, install FluidSynth, & cleanup in one docker layer
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list && \
    apt-get update && apt-get build-dep fluidsynth --no-install-recommends -y && \
    curl -Ls -o - https://github.com/FluidSynth/fluidsynth/archive/v2.1.2.tar.gz | tar -C /tmp/ -xzvf - && \
    cd /tmp/fluidsynth-2.1.2 && mkdir build && cd build/ && \
    cmake .. && \
    make && make check && \
    make install && \
    make clean && cd /tmp/ && rm -rf /tmp/fluidsynth-2.1.2/ && \
    apt-get autoremove -y

COPY docker/etc/udev/rules.d/* /etc/udev/rules.d/
RUN /usr/sbin/adduser --system --group --gecos 'Node.js Daemon' --home /usr/src/app --shell /sbin/nologin node && \
    /usr/sbin/addgroup --system gpio && \
    /usr/sbin/usermod --append --groups i2c,gpio node

# Add app
ADD . /usr/src/app/
RUN cd /usr/src/app && npm install && npm list
RUN chmod +x /usr/src/app/run_main.sh

# Backport udev setup from newer Balena image
COPY docker/balena-backports/*.sh /usr/bin/
RUN chmod +x /usr/bin/entry.sh /usr/bin/cmd.sh

#EXPOSE 8888

USER root
ENV container docker
ENV S6_KEEP_ENV 1
ENV UDEV on
ENTRYPOINT ["/init"]
