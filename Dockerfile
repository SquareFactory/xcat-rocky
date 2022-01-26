FROM quay.io/rockylinux/rockylinux:8.4

MAINTAINER Square Factory

ENV container docker

ARG xcat_version=latest
ARG xcat_reporoot=https://xcat.org/files/xcat/repos/yum
ARG xcat_baseos=rh8

RUN (cd /lib/systemd/system/sysinit.target.wants/; \
     for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
        rm -f /lib/systemd/system/multi-user.target.wants/* && \
        rm -f /etc/systemd/system/*.wants/* && \
        rm -f /lib/systemd/system/local-fs.target.wants/* && \
        rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
        rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
        rm -f /lib/systemd/system/basic.target.wants:/* && \
        rm -f /lib/systemd/system/anaconda.target.wants/*

RUN mkdir -p /xcatdata/etc/{dhcp,goconserver,xcat} && ln -sf -t /etc /xcatdata/etc/{dhcp,goconserver,xcat} && \
    mkdir -p /xcatdata/{install,tftpboot} && ln -sf -t / /xcatdata/{install,tftpboot}

RUN yum install -y -q wget which &&\
    wget ${xcat_reporoot}/${xcat_version}/$([[ "devel" = "${xcat_version}" ]] && echo 'core-snap' || echo 'xcat-core')/xcat-core.repo -O /etc/yum.repos.d/xcat-core.repo && \
    wget ${xcat_reporoot}/${xcat_version}/xcat-dep/${xcat_baseos}/$(uname -m)/xcat-dep.repo -O /etc/yum.repos.d/xcat-dep.repo && \
    yum install -y \
       xCAT \
       openssh-server \
       rsyslog \
       createrepo \
       chrony \
       initscripts \
       man \
       nano \
       pigz \
       epel-release 

RUN yum install -y -q screen && \
    yum clean all

RUN sed -i -e 's|#PermitRootLogin yes|PermitRootLogin yes|g' \
           -e 's|#Port 22|Port 2200|g' \
           -e 's|#UseDNS yes|UseDNS no|g' /etc/ssh/sshd_config && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "root:cluster" | chpasswd && \
    rm -rf /root/.ssh && \
    mv /xcatdata /xcatdata.NEEDINIT

RUN systemctl enable httpd && \
    systemctl enable sshd && \
    systemctl enable dhcpd && \
    systemctl enable rsyslog && \
    systemctl enable xcatd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD startup.sh /startup.sh
RUN chmod +x /startup.sh

ENV XCATROOT /opt/xcat
ENV PATH="$XCATROOT/bin:$XCATROOT/sbin:$XCATROOT/share/xcat/tools:$PATH" MANPATH="$XCATROOT/share/man:$MANPATH"
VOLUME [ "/xcatdata", "/var/log/xcat" ]

CMD [ "/startup.sh" ]

