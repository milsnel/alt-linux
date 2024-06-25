#!/bin/bash

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
nft list tables | grep -q '^nat$' || nft add table ip nat

# Создание цепочки prerouting для IPv4, если еще не создана
nft list chains ip nat | grep -q '^prerouting$' || nft add chain ip nat prerouting '{ type nat hook prerouting priority 0; }'

# Удаление старого правила для IPv4, если существует
nft delete rule inet nat prerouting ip daddr 192.168.100.2 tcp dport 22
# Добавление нового правила перенаправления трафика с порта 22 на указанный порт для IPv4
nft add rule inet nat prerouting ip daddr 192.168.100.2 tcp dport 22 dnat to 192.168.100.2:$new_port

nft delete rule ip nat prerouting ip daddr 2001:11::2 tcp dport 22

nft add rule inet nat prerouting ip6 daddr 2001:11::2 tcp dport 22 dnat to [2000:100::2]:$new_port


# Создание таблицы NAT для IPv6, если еще не создана

# Сохранение конфигурации
nft list ruleset | tee /etc/nftables/nftables.nft

# Перезапуск службы nftables для применения конфигурации
systemctl restart nftables

echo "Перенаправление трафика с порта 22 на порт $new_port выполнено успешно."
