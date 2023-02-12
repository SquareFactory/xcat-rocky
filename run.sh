#/bin/env bash
podman run -d \
     --name xcatmn  \
     --privileged   \
     --cgroupns private \
     --cgroup-manager=cgroupfs \
     -v /sys/fs/cgroup:/sys/fs/cgroup:ro  \
     -v ./xcatdata:/xcatdata     \
     -v ./logs:/var/log  \
     -v ./customer_data:/customer_data   \
     ghcr.io/squarefactory/xcat-rocky:0.2.1-xcat2.16.3-rocky8.4
