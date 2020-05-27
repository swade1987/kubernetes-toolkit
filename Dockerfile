FROM alpine:3
LABEL MAINTAINER Steven Wade <steven@stevenwade.co.uk>

ARG KUBERNETES_VERSION="Unknown"

# Install necessary tooling
RUN apk add --no-cache curl bash execline findutils git openssh-client && rm -rf /var/cache/apk/*

# Copy in rego policies to work with Conftest.
COPY policies /policies/

COPY install.sh /install.sh
RUN chmod +x /install.sh
RUN /install.sh ${KUBERNETES_VERSION}

ENV KUBEVAL_SCHEMA_LOCATION=file:///usr/local/kubeval/schemas

CMD ["/bin/sh"]
