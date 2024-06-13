#!/bin/bash

hostnamectl set-hostname HQ-SRV

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
ENS34_OPTIONS="/etc/net/ifaces/ens34/options"
if [ -f "$ENS34_OPTIONS" ]; then
    sed -i 's/DISABLED=yes/DISABLED=no/g' "$ENS34_OPTIONS"
    sed -i 's/MN_CONTROLLED=yes/MN_CONTROLLED=no/g' "$ENS34_OPTIONS"
    
    # Проверка и замена CONFIG_IPV6, или добавление его после CONFIG_IPV4
    if grep -q 'CONFIG_IPV6=no' "$ENS34_OPTIONS"; then
        sed -i 's/CONFIG_IPV6=no/CONFIG_IPV6=yes/g' "$ENS34_OPTIONS"
    elif ! grep -q 'CONFIG_IPV6=yes' "$ENS34_OPTIONS"; then
        # Если строки CONFIG_IPV6 нет, добавляем её после строки CONFIG_IPV4=yes
        sed -i '/CONFIG_IPV4=yes/a CONFIG_IPV6=yes' "$ENS34_OPTIONS"
    fi
else
    error_exit "Файл $ENS34_OPTIONS не найден."
fi

echo 44.44.44.144/24 > "$ENS34_DIR/ipv4address"
echo 2001:44::144/64 > "$ENS34_DIR/ipv6address"



# Restart network service
systemctl restart network || error_exit "Не удалось перезапустить сетевую службу."

exec bash
