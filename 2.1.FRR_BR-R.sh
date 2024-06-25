#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
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
network 192.168.200.0/29 area 0
network 172.16.100.0/24 area 0
exit

interface GREtun
no ip ospf network broadcast
no ip ospf passive
exit

do wr mem

router ospf6
ospf6 router-id 22.22.22.2
exit

interface GREtun
ipv6 ospf6 area 0
exit

interface ens34
ipv6 ospf6 area 0
exit

do wr mem
EOF
