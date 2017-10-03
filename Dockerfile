FROM jenkins/jenkins:lts-alpine

# Install plugins, if they aren't already
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Suppress plugin install banner
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Installing packages, need to be root to do so
USER root

# We need a more recent docker, jenkins:lts-alpine is currently pegged to Alpine 3.5, so pull docker from 3.6
# We also need ssl support for wget
RUN echo "@v3.6 http://dl-cdn.alpinelinux.org/alpine/v3.6/community" >> /etc/apk/repositories
ENV PACKAGES "ca-certificates docker@v3.6 openssl python py-pip"
RUN apk add --update $PACKAGES \
    && pip install docker-compose \
    && apk --purge -v del py-pip \
    && rm -rf /var/cache/apk/*

# Download and install Rancher CLI
ENV RANCHER_CLI_VERSION 0.6.4
# The rancher tar.gz includes permissions data for the "current" folder, so don't extract to the root of /tmp since it will change the permissions :-(
RUN mkdir /tmp/rancher \
  && wget -qO- https://github.com/rancher/cli/releases/download/v${RANCHER_CLI_VERSION}/rancher-linux-amd64-v${RANCHER_CLI_VERSION}.tar.gz \
  | tar xvz -C /tmp/rancher \
  && mv /tmp/rancher/rancher-v${RANCHER_CLI_VERSION}/rancher /usr/local/bin/rancher \
  && chmod +x /usr/local/bin/rancher \
  && rm -r /tmp/rancher

# Stay as root for custom entrypoint, which will then switch back to jenkins user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
