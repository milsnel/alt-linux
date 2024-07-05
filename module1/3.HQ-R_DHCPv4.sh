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

HQ_R_DHCP_V4_SUBNET=$(get_config_value "HQ-R.DHCP.V4.SUBNET")
HQ_R_DHCP_V4_NETMASK=$(get_config_value "HQ-R.DHCP.V4.NETMASK")
HQ_R_DHCP_V4_RANGE_FROM=$(get_config_value "HQ-R.DHCP.V4.RANGE_FROM")
HQ_R_DHCP_V4_RANGE_TO=$(get_config_value "HQ-R.DHCP.V4.RANGE_TO")
HQ_R_DHCP_V4_OPTION_ROOUTERS=$(get_config_value "HQ-R.DHCP.V4.OPTION_ROOUTERS")

HQ_R_DHCP_V4_HARDWARE=$(get_config_value "HQ-R.DHCP.V4.HARDWARE")
HQ_R_DHCP_V4_FIXED_ADDRESS=$(get_config_value "HQ-R.DHCP.V4.FIXED_ADDRESS")


apt-get update && apt-get install -y dhcp-server

sed -i 's/DHCPDARGS=/DHCPDARGS=ens34/g' "/etc/sysconfig/dhcpd"

echo "Создание конфигурационного файла DHCP для IPv4..."
cat <<EOF > /etc/dhcp/dhcpd.conf
# dhcpd.conf

default-lease-time 6000;
max-lease-time 72000;

authoritative;

subnet $HQ_R_DHCP_V4_SUBNET netmask $HQ_R_DHCP_V4_NETMASK {
    range $HQ_R_DHCP_V4_RANGE_FROM $HQ_R_DHCP_V4_RANGE_TO;
    option routers $HQ_R_DHCP_V4_OPTION_ROOUTERS;
}

host hq-srv {
    hardware ethernet $HQ_R_DHCP_V4_HARDWARE;
    fixed-address $HQ_R_DHCP_V4_FIXED_ADDRESS;
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf

systemctl enable --now dhcpd