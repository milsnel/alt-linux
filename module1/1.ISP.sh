#!/bin/bash

hostnamectl set-hostname ISP

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

ISP_IP_V4_TO_HQ_R=$(get_config_value "ISP.IP_V4.TO_HQ_R")
ISP_IP_V4_TO_BR_R=$(get_config_value "ISP.IP_V4.TO_BR_R")
ISP_IP_V4_TO_CLI=$(get_config_value "ISP.IP_V4.TO_CLI")

ISP_IP_V6_TO_HQ_R=$(get_config_value "ISP.IP_V6.TO_HQ_R")
ISP_IP_V6_TO_BR_R=$(get_config_value "ISP.IP_V6.TO_BR_R")
ISP_IP_V6_TO_CLI=$(get_config_value "ISP.IP_V6.TO_CLI")

DEFAULT_OPTIONS="/etc/net/ifaces/default/options"
if [ -f "$DEFAULT_OPTIONS" ]; then
    sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' "$DEFAULT_OPTIONS"
else
    error_exit "Файл $DEFAULT_OPTIONS не найден."
fi

ENS34_DIR="/etc/net/ifaces/ens34"
ENS35_DIR="/etc/net/ifaces/ens35"
ENS36_DIR="/etc/net/ifaces/ens36"

mkdir "$ENS34_DIR"
mkdir "$ENS35_DIR"
mkdir "$ENS36_DIR"

# Configure ens34 interface
ENS34_OPTIONS="/etc/net/ifaces/ens34/options"

cat <<EOF > "$ENS34_OPTIONS"
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
CONFIG_IPV4=YES
CONFIG_IPV6=YES
EOF

# Copy ens34 configuration to ens35 and ens36

if [ -f "$ENS34_OPTIONS" ]; then
    cp "$ENS34_OPTIONS" "$ENS35_DIR/"
    cp "$ENS34_OPTIONS" "$ENS36_DIR/"
else
    error_exit "Файл $ENS34_OPTIONS не найден для копирования."
fi

# Set IPv4 addresses
echo "$ISP_IP_V4_TO_HQ_R" > "$ENS34_DIR/ipv4address"
echo "$ISP_IP_V4_TO_BR_R" > "$ENS35_DIR/ipv4address"
echo "$ISP_IP_V4_TO_CLI" > "$ENS36_DIR/ipv4address"

# Set IPv6 addresses
echo "$ISP_IP_V6_TO_HQ_R" > "$ENS34_DIR/ipv4address"
echo "$ISP_IP_V6_TO_BR_R" > "$ENS35_DIR/ipv4address"
echo "$ISP_IP_V6_TO_CLI" > "$ENS36_DIR/ipv4address"

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
