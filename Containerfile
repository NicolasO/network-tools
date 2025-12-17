FROM registry.access.redhat.com/ubi9/ubi:9.3

# Install SSH client, netcat, and troubleshooting tools
RUN dnf -y update && \
    dnf -y install --setopt=tsflags=nodocs \
      openssh-clients \
      nmap-ncat \
      curl \
      telnet \
      traceroute \
      tcpdump \
      bind-utils \
      iproute \
      net-tools && \
    dnf clean all

# Create a non-root user for OpenShift compatibility
RUN useradd -m -s /bin/bash appuser

USER appuser
WORKDIR /home/appuser

# Start with a shell by default
CMD ["/bin/bash"]
