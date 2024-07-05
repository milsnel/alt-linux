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

BR_R_TUNNEL_IP_V4=$(get_config_value "BR-R.TUNNEL.IP_V4")
BR_R_TUNNEL_IP_V6=$(get_config_value "BR-R.TUNNEL.IP_V6")

BR_R_TUNNEL_TUNLOCAL=$(get_config_value "BR-R.TUNNEL.TUNLOCAL")
BR_R_TUNNEL_TUNREMOTE=$(get_config_value "BR-R.TUNNEL.TUNREMOTE")

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
TUNLOCAL=$BR_R_TUNNEL_TUNLOCAL
TUNREMOTE=$BR_R_TUNNEL_TUNREMOTE
TUNOPTIONS='ttl 64'
HOST=ens33
EOF

# Создание файла ipv4address для GRE интерфейса
IPV4_FILE="$IFACE_DIR/ipv4address"
echo "$BR_R_TUNNEL_IP_V4" > "$IPV4_FILE" || error_exit "Не удалось создать файл $IPV4_FILE."

# Создание файла ipv6address для GRE интерфейса
IPV6_FILE="$IFACE_DIR/ipv6address"
echo "$BR_R_TUNNEL_IP_V6" > "$IPV6_FILE" || error_exit "Не удалось создать файл $IPV6_FILE."

# Перезапуск сетевой службы
echo "Перезапуск сетевой службы..."
systemctl restart network || error_exit "Не удалось перезапустить сетевую службу."

# Загрузка модуля gre
echo "Загрузка модуля gre..."
modprobe gre || error_exit "Не удалось загрузить модуль gre."

# Показать сетевые интерфейсы
echo "Сетевые интерфейсы:"
ip -c a || error_exit "Не удалось получить список сетевых интерфейсов."
