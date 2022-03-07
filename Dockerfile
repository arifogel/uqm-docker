# syntax=docker/dockerfile:1.1.3-experimental

# Setting the parent image to ubuntu
FROM ubuntu:18.04

# Set a Working Dir
USER root

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qq \
      build-essential \
      libogg-dev \
      libpng-dev \
      libsdl2-dev \
      libvorbis-dev \
      libz-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY uqm/sc2 /root/sc2
COPY cfgstate /root/sc2/config.state
WORKDIR /root
RUN cd sc2 \
&& echo "" | \
    ./build.sh \
    -j"${NUMPROC}" \
    uqm \
&& echo "" | \
    ./build.sh \
    uqm \
    install \
&&  cd .. \
&&  rm -rf sc2
RUN cd /usr \
&& tar -czf /root/uqm.tgz bin/uqm lib/uqm share/uqm \
&& rm -rf bin/uqm lib/uqm share/uqm

