FROM alpine:3.20.3
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

# Expose the Kubeval schema location to speed up `kubeval` executions.
ENV KUBEVAL_SCHEMA_LOCATION=file:///usr/local/kubeval/schemas

# Copy in rego policies to work with Conftest.
COPY policies/ /policies/

# Install /usr/local/bin
COPY bin/* /usr/local/bin/

CMD ["/bin/sh"]
