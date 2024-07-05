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

apt-get update && apt-get install -y frr

# Define the path to the daemons file
DAEMONS_FILE="/etc/frr/daemons"

# Enable ospfd and ospf6d in the daemons file
if [ -f "$DAEMONS_FILE" ]; then
    sed -i 's/ospfd=no/ospfd=yes/g' "$DAEMONS_FILE"
    sed -i 's/ospf6d=no/ospf6d=yes/g' "$DAEMONS_FILE"
else
    error_exit "Файл $DAEMONS_FILE не найден."
fi

# Enable and start the frr service
systemctl enable --now frr || error_exit "Не удалось включить и запустить службу frr."

# Configure OSPF and OSPF6 using vtysh
vtysh <<EOF
conf t
router ospf
passive-interface default
network 192.168.100.0/28 area 0
network 172.16.100.0/24 area 0
exit

interface GREtun
no ip ospf network broadcast
no ip ospf passive
exit

do wr mem

router ospf6
ospf6 router-id 11.11.11.2
exit

interface GREtun
ipv6 ospf6 area 0
exit

interface ens34
ipv6 ospf6 area 0
exit

do wr mem
EOF
