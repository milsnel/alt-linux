#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

apt-get update && apt-get install -y dhcp-server

sed -i 's/DHCPDARGS=/DHCPDARGS=ens34/g' "/etc/sysconfig/dhcpd"

sed -i 's/DHCPDARGS=/DHCPDARGS=ens34/g' "/etc/sysconfig/dhcpd6"

echo "Создание конфигурационного файла DHCP для IPv4..."
cat <<EOF > /etc/dhcp/dhcpd.conf
# dhcpd.conf

default-lease-time 6000;
max-lease-time 72000;

authoritative;

subnet 192.168.100.0 netmask 255.255.255.192 {
    range 192.168.100.10 192.168.100.62;
    option routers 192.168.100.1;
}

host hq-srv {
    hardware ethernet 00:0c:29:87:ed:1d;
    fixed-address 192.168.100.2;
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf

systemctl enable --now dhcpd

systemctl status dhcpd
journalctl -f -u dhcpd


echo "Создание конфигурационного файла DHCP для IPv6..."
cat <<EOF > /etc/dhcp/dhcpd6.conf
# Server configuration file example for DHCPV6

default-lease-time 2592000;
preferred-lifetime 604800;

option dhcp-renewal-time 36000;
option dhcp-rebinding-time 72000;

allow leasequery;
option dhcp6.preference 255;
option dhcp6.info-refresh-time 21600;

subnet6 2000:180::/122 {
    range6 2000:100::2 2000:100::3f;
}

# host hq-srv {
#   host-identifier option dhcp6.client-id <DUID>;
#   fixed-address6 2000:100::1;
#   fixed-prefix6 2000:100::/122;
# }
EOF

systemctl enable --now dhcpd6
dhcpd -t -cf /etc/dhcp/dhcpd.conf

journalctl -f -u dhcpd6.service

echo "systemctl restart dhcpd6"