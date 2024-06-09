#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

apt-get update && apt-get install -y dhcp-server

sed -i 's/DHCPDARGS=/DHCPDARGS=ens34/g' "/etc/sysconfig/dhcpd6"

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

dhcpd -t -cf /etc/dhcp/dhcpd6.conf

systemctl enable --now dhcpd6

journalctl -f -u dhcpd6.service

echo "systemctl restart dhcpd6"