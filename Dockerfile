FROM alpine:3.21.2
LABEL MAINTAINER="Steven Wade <steven@stevenwade.co.uk>"

ARG KUBERNETES_VERSION="Unknown"

# Install necessary tooling
RUN apk add --no-cache \
  curl \
  bash \
  execline \
  findutils \
  git \
  make \
  openssh-client \
  && rm -rf /var/cache/apk/*

# Install Python 3
RUN apk add --update python3 py3-pip

# Install necessary packages
COPY src/install-dependencies.sh /install-dependencies.sh
RUN /install-dependencies.sh ${KUBERNETES_VERSION}

# Install /usr/local/bin
COPY bin/* /usr/local/bin/

CMD ["/bin/sh"]
