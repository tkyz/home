# syntax = docker/dockerfile:1.0-experimental

ARG DOCKER_BUILDING=1
ARG DOCKER_TAG=debian

#----------------------------------------------------------------
FROM ${DOCKER_TAG}:latest

# 内部完結

ARG DOCKER_BUILDING
ARG DOCKER_TAG

WORKDIR /root/

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash"]

# 外部参照

COPY  ./*.sh                /workdir/
COPY "./${DOCKER_TAG}/*.sh" /workdir/

RUN "/workdir/dependencies.sh"
SHELL ["/bin/bash", "-euc"]

RUN \
  source /workdir/bashrc.sh && \
  /workdir/install.sh && \
  rm -rf /workdir/
