#!/bin/bash

set -e  # Остановка выполнения при ошибке
set -x  # Вывод каждой команды перед выполнением

# Обновление и установка nftables
apt-get update && apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables

# Добавление таблицы и цепочек
nft add table ip nat
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'

# Добавление правил
nft add rule ip nat postrouting ip saddr 11.11.11.0/24 oifname "ens33" counter masquerade
nft add rule ip nat postrouting ip saddr 22.22.22.0/24 oifname "ens33" counter masquerade
nft add rule ip nat postrouting ip saddr 33.33.33.0/24 oifname "ens33" counter masquerade

# Вывод набора правил
nft list ruleset

# Сохранение набора правил в файл
nft list ruleset | tail -n8 | tee -a /etc/nftables/nftables.nft

# Перезапуск службы nftables
systemctl restart nftables

# Окончательный вывод набора правил для проверки
nft list ruleset
