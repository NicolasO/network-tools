Got it ✅ — I'll update the Containerfile in the Markdown so it also installs **iproute** (for `ip`, `ss`, etc.) and **net-tools** (for classic `ifconfig`, `netstat`, etc.).  

Here’s the full updated Markdown with your requested changes:  

---

# UBI9 Container with SSH client, Netcat, and extended network troubleshooting tools for OpenShift

This repository provides a UBI9-based container image that includes:

- **SSH client** (`openssh-clients`)
- **Netcat** (`nmap-ncat`)
- **HTTP/other protocol tools** (`curl`, `telnet`)
- **Network diagnostics tools** (`traceroute`, `tcpdump`, `bind-utils` including `dig`)
- **IP utilities** (`iproute` provides `ip`, `ss`, etc.)
- **Legacy network utilities** (`net-tools` provides `ifconfig`, `netstat`, etc.)

It is intended for use as a troubleshooting/jump container in OpenShift.  
You exec/rsh into the pod and run tools directly — the container **does NOT** run an SSH server.

---

## Containerfile

Save this as `Containerfile` in your build context:

```Dockerfile
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
```

---

## Example Usage in OpenShift

### 1. Switch to your project
```bash
oc project tools
```

---

### 2. Build and push to the internal OpenShift registry
```bash
oc new-build --name=ssh-ncat --strategy=docker --binary=true
oc start-build ssh-ncat --from-dir=. --follow
```
Image will be in:
```
image-registry.openshift-image-registry.svc:5000//ssh-ncat:latest
```

---

### 3. Run a Pod with the image
```bash
oc run ssh-ncat-test \
    --image=image-registry.openshift-image-registry.svc:5000/tools/ssh-ncat:latest \
    --restart=Never \
    --command -- sleep infinity
```

---

### 4. Exec or rsh into the pod
```bash
oc rsh ssh-ncat-test
# Or
oc exec -it ssh-ncat-test -- /bin/bash
```

---

### 5. Use tools inside the pod
```bash
# SSH to remote host
ssh user@remote-host.example.com

# Netcat test
ncat remote-host.example.com 443

# DNS lookup
dig @8.8.8.8 example.com

# Traceroute
traceroute example.com

# Curl/telnet
curl -Iv https://remote-host.example.com
telnet remote-host.example.com 80

# IP utilities
ip a
ss -lnt
ifconfig
netstat -an

# tcpdump (may need extra privileges)
tcpdump -n -c 100
```

---

## Example Deployment YAML
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ssh-ncat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ssh-ncat
  template:
    metadata:
      labels:
        app: ssh-ncat
    spec:
      containers:
      - name: ssh-ncat
        image: image-registry.openshift-image-registry.svc:5000/tools/ssh-ncat:latest
        command: ["/bin/bash", "-c", "sleep infinity"]
```

---

## Security Notes

- Runs as **non-root** by default for OpenShift SCC compliance.
- No SSH server, only client tools.
- Avoid copying private keys into pods in production — prefer `oc exec` or SSH agent forwarding.
- `tcpdump` may require privileges to capture traffic; use `oc debug` if needed.

---

## Minimal Makefile for Podman build & push

```Makefile
# Registry configuration
REGISTRY ?= docker.io
USERNAME ?= youruser
IMAGE_NAME ?= ssh-ncat
TAG ?= latest
IMAGE ?= $(REGISTRY)/$(USERNAME)/$(IMAGE_NAME):$(TAG)

BUILD_CONTEXT ?= .
CONTAINERFILE ?= Containerfile

.PHONY: build push login clean

build:
	podman build -t $(IMAGE) -f $(CONTAINERFILE) $(BUILD_CONTEXT)

push: build
	podman push $(IMAGE)

login:
	podman login $(REGISTRY)

clean:
	podman rmi -f $(IMAGE) || true
```

---
