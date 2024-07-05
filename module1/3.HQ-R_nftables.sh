#!/bin/bash
set -e

set -x

CONFIG_FILE="../neverlose.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "Файл $CONFIG_FILE не найден."
fi

# Функция для чтения значений из конфигурационного файла
get_config_value() {
    local key="$1"
    grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2
}

HQ_R_NFTABLES_HQ_SRV=$(get_config_value "HQ-R.NFTABLES.HQ_SRV")

# Установка nftables, если еще не установлен
apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables

sleep 5

# Создание таблицы NAT, если еще не создана
nft list tables | grep -q '^nat$' || nft add table ip nat

# Создание цепочки postrouting, если еще не создана
nft list chains ip nat | grep -q '^postrouting$' || nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'

# Добавление правила masquerade для раздачи интернета
nft list rules ip nat postrouting | grep -q 'masquerade' || nft add rule ip nat postrouting ip saddr "$HQ_R_NFTABLES_HQ_SRV" oifname 'ens33' counter masquerade

# Сохранение конфигурации
nft list ruleset | tee /etc/nftables/nftables.nft

# Перезапуск службы nftables для применения конфигурации
systemctl restart nftables
