#!/bin/bash

apt-get install -y radvd

echo net.ipv6.conf.ens34.accept_ra = 2 >> /etc/net/sysctl.conf

systemctl restart network

cat <<EOF > /etc/radvd.conf 
#NOTE: there is no such thing as a working “by-default” configuration file.
#At least the prefix needs to be specified. Please consult the radud.conf(5)
# man page and/or /usr/share/doc/radud—*/radud.conf example for help.
#
#
#
#
interface ens34
{
    AdvSendAdvert on;
    AdvManagedFlag on;
    AdvOtherConfigFlag on;
    prefix 2000:100::/124
    {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };
};
EOF


systemctl restart dhcpd6
systemctl enable --now radvd