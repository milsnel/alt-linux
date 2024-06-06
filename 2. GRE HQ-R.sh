#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Создание каталога для GRE интерфейса
IFACE_DIR="/etc/net/ifaces/GREtun"
echo "Создание каталога $IFACE_DIR..."
mkdir -p "$IFACE_DIR" || error_exit "Не удалось создать каталог $IFACE_DIR."

# Создание файла options для GRE интерфейса
OPTIONS_FILE="$IFACE_DIR/options"
echo "Создание файла $OPTIONS_FILE..."
cat <<EOF > "$OPTIONS_FILE"
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=11.11.11.2
TUNREMOTE=22.22.22.2
TUNOPTIONS='ttl 64'
HOST=ens33
EOF

# Создание файла ipv4address для GRE интерфейса
IPV4_FILE="$IFACE_DIR/ipv4address"
echo "172.16.100.1/24" > "$IPV4_FILE" || error_exit "Не удалось создать файл $IPV4_FILE."

# Создание файла ipv6address для GRE интерфейса
IPV6_FILE="$IFACE_DIR/ipv6address"
echo "2001:100::1/64" > "$IPV6_FILE" || error_exit "Не удалось создать файл $IPV6_FILE."

# Перезапуск сетевой службы
echo "Перезапуск сетевой службы..."
systemctl restart network || error_exit "Не удалось перезапустить сетевую службу."

# Загрузка модуля gre
echo "Загрузка модуля gre..."
modprobe gre || error_exit "Не удалось загрузить модуль gre."

# Показать сетевые интерфейсы
echo "Сетевые интерфейсы:"
ip -c a || error_exit "Не удалось получить список сетевых интерфейсов."
