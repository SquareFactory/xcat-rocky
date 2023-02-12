#!/bin/bash
is_ubuntu=$(test -f /etc/debian_version && echo Y)
[[ -z ${is_ubuntu} ]] && logadm="root:" || logadm="syslog:adm"
chown -R ${logadm} /var/log/xcat/
. /etc/profile.d/xcat.sh
ps -ax
if [[ -d "/xcatdata.NEEDINIT" ]]; then
    echo "initializing xCAT ..."
    if [ ! -f "/xcatdata/.init-finished" ]; then
        echo "first initalization, copying template..."
        rsync -a /xcatdata.NEEDINIT/ /xcatdata

        echo "initalizing database."
        xcatconfig --database

        touch /xcatdata/.init-finished
    fi

    echo "initializing networks table if necessary..."
    xcatconfig --updateinstall
    XCATBYPASS=1 tabdump site | grep domain || XCATBYPASS=1 chtab key=domain site.value=example.com

    if ! [ -L /root/.xcat ]; then
        if ! [ -d /xcatdata/.xcat ]; then
            echo "backup data not found, regenerating certificates and copying..."
            xcatconfig -c
            rsync -a /root/.xcat/* /xcatdata/.xcat
        fi
        echo "create symbol link for /root/.xcat..."
        rm -rf /root/.xcat/
        ln -sf -t /root /xcatdata/.xcat
    fi

    if [ -d /xcatdata/.ssh ]; then
        echo "copy backup keys in /root/.ssh..."
        rsync -a /xcatdata/.ssh/ /root/.ssh/
        chmod 600 /root/.ssh/*
    else
        echo "backup keys not found, copying keys to /xcatdata/.ssh..."
        xcatconfig --sshkeys
        mkdir -p /xcatdata/.ssh
        rsync -a /root/.ssh/ /xcatdata/.ssh/
        chmod 600 /xcatdata/.ssh/*
    fi

    echo "reconfiguring hosts..."
    makehosts
    echo "reconfiguring dns..."
    makedns
    echo "reconfiguring dhcpd config..."
    makedhcp -n
    echo "reconfiguring dhcpd leases..."
    makedhcp -a

    echo "initializing loop devices..."
    # workaround for no loop device could be used by copycds
    for i in {0..7}; do
        test -b /dev/loop$i || mknod /dev/loop$i -m0660 b 7 $i
    done
    # workaround for missing `switch_macmap` (#13)
    ln -sf /opt/xcat/bin/xcatclient /opt/xcat/probe/subcmds/bin/switchprobe
    mv /xcatdata.NEEDINIT /xcatdata.orig
fi

# Stop xcat and let systemd do its job
systemctl restart --no-block xcatd

cat /etc/motd
HOSTIPS=$(ip -o -4 addr show up | grep -v "\<lo\>" | xargs -I{} expr {} : ".*inet \([0-9.]*\).*")
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "welcome to Dockerized xCAT, please login with"
[[ -n "$HOSTIPS" ]] && for i in $HOSTIPS; do echo "   ssh root@$i -p 2200  "; done && echo "The initial password is \"cluster\""
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

#exec /sbin/init
rm -f /etc/nologin /var/run/nologin
