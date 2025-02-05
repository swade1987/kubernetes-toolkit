FROM alpine:3.21.2
LABEL MAINTAINER="Steven Wade <steven@stevenwade.co.uk>"

ARG KUBERNETES_VERSION="Unknown"

# Enable Edge Community Repo
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install necessary tooling with a specific Buildah version
RUN apk update && apk add --no-cache \
  curl \
  bash \
  buildah=1.38.1-r0 \
  execline \
  findutils \
  git \
  make \
  openssh-client && \
  rm -rf /var/cache/apk/*

# Install Python 3
RUN apk add --update python3 py3-pip

# Install necessary packages
COPY src/install-dependencies.sh /install-dependencies.sh
RUN /install-dependencies.sh ${KUBERNETES_VERSION}

# Install /usr/local/bin
COPY bin/* /usr/local/bin/

CMD ["/bin/sh"]
