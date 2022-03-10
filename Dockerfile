FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ENV HOME="/config"

# cancel:   sed -i "s/fonts.googleapis.com/wgq.shwlst.com:40002/g" /usr/lib/node_modules/apidoc/template-single/index.html && \
RUN \
  echo "**** install node repo ****" && \
  curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo 'deb https://deb.nodesource.com/node_14.x focal main' \
    > /etc/apt/sources.list.d/nodesource.list && \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    build-essential \
    nodejs \
    pkg-config \
    python3 && \
  echo "**** install runtime dependencies ****" && \
  apt-get install -y \
    git \
    jq \
    nano \
    net-tools \
    libatomic1 \
    sudo \
    clang-format \
    upx \
    cron \
    python3-pip \
    gogoprotobuf \
    yarn && \
  echo "**** install apidoc ****" && \
  npm install apidoc -g && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
    | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** patch 4.0.2 ****" && \
  if [ "${CODE_RELEASE}" = "4.0.2" ] && [ "$(uname -m)" !=  "x86_64" ]; then \
    cd /app/code-server && \
    npm i --production @node-rs/argon2; \
  fi && \
  echo "**** setup go clean job ****" && \
  echo "3 3 * * * /opt/go/bin/go clean -cache" >> /var/spool/cron/crontabs/abc && \
  echo "3 2 * * * /bin/rm -rf /config/data/logs/*" >> /var/spool/cron/crontabs/abc && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
