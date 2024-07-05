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

HQ_R_DHCP_V6_SUBNET6=$(get_config_value "HQ-R.DHCP.V6.SUBNET6")
HQ_R_DHCP_V6_RANGE_FROM=$(get_config_value "HQ-R.DHCP.V6.RANGE_FROM")
HQ_R_DHCP_V6_RANGE_TO=$(get_config_value "HQ-R.DHCP.V6.RANGE_TO")

HQ_R_DHCP_V6_CLIENT_ID=$(get_config_value "HQ-R.DHCP.V6.CLIENT_ID")
HQ_R_DHCP_V6_FIXED_ADDRESS=$(get_config_value "HQ-R.DHCP.V6.FIXED_ADDRESS")
HQ_R_DHCP_V6_FIXED_FPREFIX=$(get_config_value "HQ-R.DHCP.V6.FIXED_PREFIX")

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

subnet6 $HQ_R_DHCP_V6_SUBNET6{
    range6 $HQ_R_DHCP_V6_RANGE_FROM $HQ_R_DHCP_V6_RANGE_TO;
}

# host hq-srv {
#   host-identifier option dhcp6.client-id $HQ_R_DHCP_V6_CLIENT_ID;
#   fixed-address6 $HQ_R_DHCP_V6_FIXED_ADDRES;
#   fixed-prefix6 $HQ_R_DHCP_V6_FIXED_FPREFIX;
# }
EOF

dhcpd -t -6 -cf /etc/dhcp/dhcpd6.conf

systemctl enable --now dhcpd6

journalctl -f -u dhcpd6.service

echo "systemctl restart dhcpd6"