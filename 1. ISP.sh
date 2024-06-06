#!/bin/bash

hostnamectl set-hostname ISP

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

# Configure ens34 interface
ENS34_OPTIONS="/etc/net/ifaces/ens34/options"
if [ -f "$ENS34_OPTIONS" ]; then
    sed -i 's/DISABLED=yes/DISABLED=no/g' "$ENS34_OPTIONS"
    sed -i 's/MN_CONTROLLED=yes/MN_CONTROLLED=no/g' "$ENS34_OPTIONS"
else
    error_exit "Файл $ENS34_OPTIONS не найден."
fi

# Copy ens34 configuration to ens35 and ens36
ENS34_DIR="/etc/net/ifaces/ens34"
ENS35_DIR="/etc/net/ifaces/ens35"
ENS36_DIR="/etc/net/ifaces/ens36"
if [ -f "$ENS34_OPTIONS" ]; then
    cp "$ENS34_OPTIONS" "$ENS35_DIR/"
    cp "$ENS34_OPTIONS" "$ENS36_DIR/"
else
    error_exit "Файл $ENS34_OPTIONS не найден для копирования."
fi

# Set IPv4 addresses
echo 11.11.11.1/24 > "$ENS34_DIR/ipv4address"
echo 22.22.22.1/24 > "$ENS35_DIR/ipv4address"
echo 33.33.33.1/24 > "$ENS36_DIR/ipv4address"

# Set IPv6 addresses
echo 2001:11::1/64 > "$ENS34_DIR/ipv6address"
echo 2001:22::1/64 > "$ENS35_DIR/ipv6address"
echo 2001:33::1/64 > "$ENS36_DIR/ipv6address"

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
