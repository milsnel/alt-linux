#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

apt-get update && apt-get install -y dhcp-server

sed -i 's/DHCPDARGS=/DHCPDARGS=ens34/g' "/etc/sysconfig/dhcpd"

echo "Создание конфигурационного файла DHCP для IPv4..."
cat <<EOF > /etc/dhcp/dhcpd.conf
# dhcpd.conf

default-lease-time 6000;
max-lease-time 72000;

authoritative;

subnet 192.168.100.0 netmask 255.255.255.240 {
    range 192.168.100.3 192.168.100.14;
    option routers 192.168.100.1;
}

host hq-srv {
    hardware ethernet 00:0c:29:bf:29:7e;
    fixed-address 192.168.100.2;
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf

systemctl enable --now dhcpd