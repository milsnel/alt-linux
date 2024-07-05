#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

CONFIG_FILE="../neverlose.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "Файл $CONFIG_FILE не найден."
fi

# Функция для чтения значений из конфигурационного файла
get_config_value() {
    local key="$1"
    grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2
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

subnet6 2000:100::/124{
    range6 2000:100::3 2000:100::f;
}

# host hq-srv {
#   host-identifier option dhcp6.client-id 00:04:1d:cc:4a:98:dd:cd:73:32:66:5d:3e:92:aa:f5:89:e5;
#   fixed-address6 2000:100::2;
#   fixed-prefix6 2000:100::/124;
# }
EOF

dhcpd -t -6 -cf /etc/dhcp/dhcpd6.conf

systemctl enable --now dhcpd6

journalctl -f -u dhcpd6.service

echo "systemctl restart dhcpd6"