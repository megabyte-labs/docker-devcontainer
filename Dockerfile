FROM ubuntu:focal AS devcontainer

ARG DOCKER_VERSION="latest"
ARG ENABLE_NONROOT_DOCKER="true"
ARG INSTALL_ZSH="true"
ARG PASSWORD="codingfor72hours"
ARG UPGRADE_PACKAGES="true"
ARG USE_MOBY="true"
ARG USER_GID="1111"
ARG USER_UID="1111"
ARG USERNAME="megabyte"

ENV BREW_PREFIX=/home/linuxbrew/.linuxbrew
ENV DBUS_SESSION_BUS_ADDRESS="autolaunch:"
ENV DISPLAY=":1"
ENV DOCKER_BUILDKIT=1
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"
ENV NOVNC_PORT="6080"
ENV OSTYPE="linux-gnu"
ENV PATH="$PATH:/usr/local/go/bin"

ENV VNC_DPI="96"
ENV VNC_PORT="5901"
ENV VNC_RESOLUTION="1440x768x16"

WORKDIR /work

COPY scripts/*.sh /tmp/scripts/
COPY bin/ /usr/local/bin/
COPY local/initctl ./

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && bash /tmp/scripts/common.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
  && bash /tmp/scripts/desktop.sh "${USERNAME}" "${PASSWORD}" "true" "${VNC_PORT}" "${NOVNC_PORT}" \
  && bash /tmp/scripts/dind.sh "${ENABLE_NONROOT_DOCKER}" "${USERNAME}" "${USE_MOBY}" "${DOCKER_VERSION}" \
  && bash /tmp/scripts/sshd.sh "2222" "${USERNAME}" "false" "${PASSWORD}" "true" \
  && apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  file \
  gcc \
  git \
  grep \
  gzip \
  jo \
  jq \
  libnss3-tools \
  make \
  procps \
  rsync \
  ruby \
  sshfs \
  sshpass \
  sudo \
  systemd \
  systemd-cron \
  systemd-sysv \
  && apt-get clean \
  && rm -rf \
  /usr/share/doc \
  /usr/share/man \
  /tmp/* \
  /var/tmp/* \
  /var/lib/apt/lists/* \
  /sbin/initctl \
  && mv initctl /sbin/initctl \
  && rm -rf /var/lib/apt/lists/* \
  && cd /lib/systemd/system/sysinit.target.wants/ \
  && ls | grep -v systemd-tmpfiles-setup | xargs rm -f "$1" \
  && rm -f /lib/systemd/system/multi-user.target.wants/* \
  /etc/systemd/system/*.wants/* \
  /lib/systemd/system/local-fs.target.wants/* \
  /lib/systemd/system/sockets.target.wants/*udev* \
  /lib/systemd/system/sockets.target.wants/*initctl* \
  /lib/systemd/system/basic.target.wants/* \
  /lib/systemd/system/anaconda.target.wants/* \
  /lib/systemd/system/plymouth* \
  /lib/systemd/system/systemd-update-utmp* \
  /lib/systemd/system/systemd*udev* \
  /lib/systemd/system/getty.target \
  && curl -sL https://raw.githubusercontent.com/docker-slim/docker-slim/master/scripts/install-dockerslim.sh | sudo -E bash - \
  && curl -sSL https://golang.org/dl/go1.18.linux-amd64.tar.gz > /tmp/go.tar.gz \
  && tar -C /usr/local -xzf /tmp/go.tar.gz

USER megabyte

WORKDIR /home/megabyte

ENV GOPATH="/home/megabyte/.local/go"
ENV PATH=${GOPATH}/bin:${BREW_PREFIX}/sbin:${BREW_PREFIX}/bin:/home/megabyte/.local/bin:/home/megabyte/.cargo/bin:${PATH}

COPY start.sh .config Taskfile.yml ./

RUN set -ex \
  && sudo chown -R "${USERNAME}:${USERNAME}" . \
  && mkdir -p ~/.local/bin ~/.local/go ~/.cargo/bin \
  && curl https://sh.rustup.rs -sSf | sh -s -- -y \
  && START=false bash start.sh \
  && task \
  install:apt:gitlab-runner \
  install:apt:helm \
  install:apt:kubectl \
  install:apt:node \
  install:apt:python \
  install:apt:waypoint

RUN mkdir -p "$HOME/.local/go" &&task install:go:bundle \
  install:npm:bundle \
  install:pipx:bundle \
  install:rust:bundle \
  install:software:poetry \
  && rm -rf *

VOLUME ["/var/lib/docker"]
VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

ENTRYPOINT ["/usr/local/share/desktop-init.sh", "/usr/local/share/ssh-init.sh", "/usr/local/share/docker-init.sh"]
CMD ["/lib/systemd/systemd"]

ARG BUILD_DATE
ARG REVISION
ARG VERSION

LABEL maintainer="Megabyte Labs <help@megabyte.space>"
LABEL org.opencontainers.image.authors="Brian Zalewski <brian@megabyte.space>"
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.description="The DevContainer Docker-based development environment for Megabyte Labs projects"
LABEL org.opencontainers.image.documentation="https://github.com/ProfessorManhattan/docker-devcontainer/blob/master/README.md"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.source="https://gitlab.com/megabyte-labs/docker/software/devcontainer.git"
LABEL org.opencontainers.image.url="https://megabyte.space"
LABEL org.opencontainers.image.vendor="Megabyte Labs"
LABEL org.opencontainers.image.version=$VERSION
LABEL space.megabyte.type="software"
