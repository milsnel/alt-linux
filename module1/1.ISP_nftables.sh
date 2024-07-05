#!/bin/bash

set -e  # Остановка выполнения при ошибке
set -x  # Вывод каждой команды перед выполнением

CONFIG_FILE="../neverlose.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
    error_exit "Файл $CONFIG_FILE не найден."
fi

# Функция для чтения значений из конфигурационного файла
get_config_value() {
    local key="$1"
    grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2
}

ISP_NFTABLES_HQ_R=$(get_config_value "ISP.NFTABLES.HQ_R")
ISP_NFTABLES_BR_R=$(get_config_value "ISP.NFTABLES.BR_R")
ISP_NFTABLES_CLI=$(get_config_value "ISP.NFTABLES.CLI")

# Обновление и установка nftables
apt-get update && apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables
sleep 5
# Добавление таблицы и цепочек
nft add table ip nat
sleep 5
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
sleep 5
# Добавление правил
nft add rule ip nat postrouting ip saddr "$ISP_NFTABLES_HQ_R" oifname "ens33" counter masquerade
sleep 1
nft add rule ip nat postrouting ip saddr "$ISP_NFTABLES_BR_R" oifname "ens33" counter masquerade
sleep 1
nft add rule ip nat postrouting ip saddr "$ISP_NFTABLES_CLI" oifname "ens33" counter masquerade
sleep 1
# Вывод набора правил
nft list ruleset
sleep 1
# Сохранение набора правил в файл
nft list ruleset | tail -n8 | tee -a /etc/nftables/nftables.nft
sleep 1
# Перезапуск службы nftables
systemctl restart nftables
sleep 1
# Окончательный вывод набора правил для проверки
nft list ruleset
