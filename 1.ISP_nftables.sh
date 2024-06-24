#!/bin/bash

set -e  # Остановка выполнения при ошибке
set -x  # Вывод каждой команды перед выполнением

# Обновление и установка nftables
apt-get update && apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables
sleep 1
# Добавление таблицы и цепочек
nft add table ip nat
sleep 5
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
sleep 5
# Добавление правил
nft add rule ip nat postrouting ip saddr 11.11.11.0/24 oifname "ens33" counter masquerade
sleep 1
nft add rule ip nat postrouting ip saddr 22.22.22.0/24 oifname "ens33" counter masquerade
sleep 1
nft add rule ip nat postrouting ip saddr 33.33.33.0/24 oifname "ens33" counter masquerade
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
