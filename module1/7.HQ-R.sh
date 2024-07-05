#!/bin/bash

set -e

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

HQ_R_NFTABLES_PREROUTING_IP_V4_HQ_SRV=$(get_config_value "HQ-R.NFTABLES.PREROUTING.IP_V4.HQ_SRV")
HQ_R_NFTABLES_PREROUTING_IP_V6_HQ_SRV=$(get_config_value "HQ-R.NFTABLES.PREROUTING.IP_V6.HQ_SRV")

# Установка nftables, если еще не установлен
apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables

sleep 5

# Ввод порта для перенаправления
read -p "Введите порт для перенаправления трафика с порта 22: " new_port

# Проверка, является ли введенное значение числом
if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: Введено не числовое значение."
    exit 1
fi
# Создание таблицы NAT для IPv4, если еще не создана
nft add table inet nat

# Создание цепочки prerouting для IPv4, если еще не создана
 nft add chain inet nat prerouting '{ type nat hook prerouting priority 0; }'

# Удаление старого правила для IPv4, если существует
# Добавление нового правила перенаправления трафика с порта 22 на указанный порт для IPv4
nft add rule inet nat prerouting ip daddr "$HQ_R_NFTABLES_PREROUTING_IP_V4_HQ_SRV" tcp dport 22 dnat to "$HQ_R_NFTABLES_PREROUTING_IP_V4_HQ_SRV":$new_port
nft add rule inet nat prerouting ip6 daddr "$HQ_R_NFTABLES_PREROUTING_IP_V6_HQ_SRV" tcp dport 22 dnat to ["$HQ_R_NFTABLES_PREROUTING_IP_V6_HQ_SRV"]:$new_port


# Создание таблицы NAT для IPv6, если еще не создана

# Сохранение конфигурации
nft list ruleset | tee /etc/nftables/nftables.nft

# Перезапуск службы nftables для применения конфигурации
systemctl restart nftables

echo "Перенаправление трафика с порта 22 на порт $new_port выполнено успешно."
