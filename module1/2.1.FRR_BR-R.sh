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

BR_R_FRR_NETWORK_HQ_SRV=$(get_config_value "BR-R.FRR.NETWORK.HQ_SRV")
BR_R_FRR_NETWORK_TUNNEL=$(get_config_value "BR-R.FRR.NETWORK.TUNNEL")
BR_R_FRR_NETWORK_ROUTER_ID=$(get_config_value "BRS-R.FRR.NETWORK.ROUTER_ID")

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
network $BR_R_FRR_NETWORK_HQ_SRV area 0
network $BR_R_FRR_NETWORK_TUNNEL area 0
exit

interface GREtun
no ip ospf network broadcast
no ip ospf passive
exit

do wr mem

router ospf6
ospf6 router-id $BR_R_FRR_NETWORK_ROUTER_ID
exit

interface GREtun
ipv6 ospf6 area 0
exit

interface ens34
ipv6 ospf6 area 0
exit

do wr mem
EOF
