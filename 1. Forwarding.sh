#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

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
