#!/bin/bash

hostnamectl set-hostname BR-R

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

DEFAULT_OPTIONS="/etc/net/ifaces/default/options"
if [ -f "$DEFAULT_OPTIONS" ]; then
    sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' "$DEFAULT_OPTIONS"
else
    error_exit "Файл $DEFAULT_OPTIONS не найден."
fi

# Configure ens33 interface
ENS33_OPTIONS="/etc/net/ifaces/ens33/options"
cat <<EOF > "$ENS33_OPTIONS"
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
CONFIG_IPV4=YES
CONFIG_IPV6=YES
EOF



# Copy ens33 configuration to ens34 and ens35

ENS33_DIR="/etc/net/ifaces/ens33"
ENS34_DIR="/etc/net/ifaces/ens34"

mkdir "$ENS34_DIR"

if [ -f "$ENS33_OPTIONS" ]; then
    cp "$ENS33_OPTIONS" "$ENS34_DIR/"
else
    error_exit "Файл $ENS34_OPTIONS не найден для копирования."
fi

# Set IPv4 addresses
echo 22.22.22.2/24 > "$ENS33_DIR/ipv4address"
echo default via 22.22.22.1 > "$ENS33_DIR/ipv4route"
echo 192.168.200.1/29 > "$ENS34_DIR/ipv4address"

# Set IPv6 addresses
echo 2001:22::2/64 > "$ENS33_DIR/ipv6address"
echo default via 2001:22::1 > "$ENS33_DIR/ipv6route"
echo 2000:200::1/125 > "$ENS34_DIR/ipv6address"

# Enable IPv4 and IPv6 forwarding
SYSCTL_CONF="/etc/net/sysctl.conf"
if [ -f "$SYSCTL_CONF" ]; then
    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1 /g' "$SYSCTL_CONF"
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