#/bin/env bash
sudo docker run -d \
     --name xcatmn  \
     --network=host  \
     --hostname xcatmn \
     --privileged   \
     -v /sys/fs/cgroup:/sys/fs/cgroup:ro  \
     -v /xcatdata:/xcatdata     \
     -v /var/log/xcat:/var/log/xcat  \
     -v /customer_data:/customer_data   \
     xcat:rocky8.4
