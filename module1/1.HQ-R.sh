#!/bin/bash

hostnamectl set-hostname HQ-R

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

HQ_R_IP_V4_TO_ISP=$(get_config_value "HQ-R.IP_V4.TO_ISP")
HQ_R_IP_V4_TO_HQ_SRV=$(get_config_value "HQ-R.IP_V4.TO_HQ_SRV")
HQ_R_IP_V4_TO_CLI=$(get_config_value "HQ-R.IP_V4.TO_CLI")

HQ_R_IP_V6_TO_ISP=$(get_config_value "HQ-R.IP_V6.TO_ISP")
HQ_R_IP_V6_TO_HQ_SRV=$(get_config_value "HQ-R.IP_V6.TO_HQ_SRV")
HQ_R_IP_V6_TO_CLI=$(get_config_value "HQ-R.IP_V6.TO_CLI")

HQ_R_GATEWAY_IP_V4=$(get_config_value "HQ-R.GATEWAY.IP_V4")
HQ_R_GATEWAY_IP_V6=$(get_config_value "HQ-R.GATEWAY.IP_V6")

DEFAULT_OPTIONS="/etc/net/ifaces/default/options"
if [ -f "$DEFAULT_OPTIONS" ]; then
    sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' "$DEFAULT_OPTIONS"
else
    error_exit "Файл $DEFAULT_OPTIONS не найден."
fi

# Configure ens33 interface
ENS33_OPTIONS="/etc/net/ifaces/ens33/options"


# Copy ens33 configuration to ens34 and ens35
ENS33_DIR="/etc/net/ifaces/ens33"
ENS34_DIR="/etc/net/ifaces/ens34"
ENS35_DIR="/etc/net/ifaces/ens35"

mkdir "$ENS34_DIR"
mkdir "$ENS35_DIR"

ENS33_OPTIONS="/etc/net/ifaces/ens33/options"

cat <<EOF > "$ENS33_OPTIONS"
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
CONFIG_IPV4=YES
CONFIG_IPV6=YES
EOF


if [ -f "$ENS33_OPTIONS" ]; then
    cp "$ENS33_OPTIONS" "$ENS34_DIR/"
    cp "$ENS33_OPTIONS" "$ENS35_DIR/"
else
    error_exit "Файл $ENS34_OPTIONS не найден для копирования."
fi

# Set IPv4 addresses
echo "$HQ_R_IP_V4_TO_ISP" > "$ENS33_DIR/ipv4address"
echo default via "$HQ_R_GATEWAY_IP_V4" > "$ENS33_DIR/ipv4route"
echo "$HQ_R_IP_V4_TO_HQ_SRV" > "$ENS34_DIR/ipv4address"
echo "$HQ_R_IP_V4_TO_CLI" > "$ENS35_DIR/ipv4address"

# Set IPv6 addresses
echo "$HQ_R_IP_V6_TO_ISP" > "$ENS33_DIR/ipv6address"
echo default via "$HQ_R_GATEWAY_IP_V6" > "$ENS33_DIR/ipv6route"
echo "$HQ_R_IP_V6_TO_HQ_SRV" > "$ENS34_DIR/ipv6address"
echo "$HQ_R_IP_V6_TO_CLI" > "$ENS35_DIR/ipv6address"

# Enable IPv4 and IPv6 forwarding
SYSCTL_CONF="/etc/net/sysctl.conf"
if [ -f "$SYSCTL_CONF" ]; then
    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' "$SYSCTL_CONF"
    if grep -q 'net.ipv4.ip_forward = 1' "$SYSCTL_CONF"; then
        sed -i '/net.ipv4.ip_forward = 1/a net.ipv6.conf.all.forwarding = 1' "$SYSCTL_CONF"
    else
        echo 'net.ipv6.conf.all.forwarding = 1' >> "$SYSCTL_CONF"
    fi
else
    error_exit "Файл $SYSCTL_CONF не найден."
fi

# Restart network service
systemctl restart network || error_exit "Не удалось перезапустить сетевую службу."

exec bash
