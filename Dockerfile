FROM balenalib/intel-edison-node:13.12-sid

RUN install_packages wget rsync gnupg2

#ENV MRAAVERSION v1.3.0  
#RUN git clone https://github.com/intel-iot-devkit/mraa.git && \  
#    cd mraa && \
#    git checkout -b build ${MRAAVERSION} && \
#    make install && \
#    cd .. && rm -rf mraa

# Verify & Unpack S6 Init overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz.sig /tmp/
RUN curl -Ls -o - https://keybase.io/justcontainers/key.asc | gpg --import && ( cd /tmp/ && gpg --trusted-key 0x2536CA16DF4FCDA2 --verify  s6-overlay-amd64.tar.gz.sig  s6-overlay-amd64.tar.gz ; exit $? )
RUN mkdir -p /tmp/s6-overlay-root
RUN tar -xzf /tmp/s6-overlay-amd64.tar.gz -C /tmp/s6-overlay-root/

# Workaround https://github.com/just-containers/s6-overlay#bin-and-sbin-are-symlinks
RUN rsync -av --ignore-existing /tmp/s6-overlay-root/ /
RUN ${CONTAINER_APP_PATH}/setup_env.sh
COPY s6-overlay-init/ /tmp/s6-etc/
RUN rsync -av --ignore-existing /tmp/s6-etc/ /etc/
# s6-fdholderd active by default
RUN s6-rmrf /etc/s6/services/s6-fdholderd/down

# Add app
ADD . /usr/src/app/
RUN chmod +x /usr/src/app/run_main.sh

RUN useradd -r -d /usr/src/app -c "node Daemon" -s /sbin/nologin --user-group node

#EXPOSE 888

ENTRYPOINT ['']
