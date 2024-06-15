#!/bin/bash

# Установка nftables, если еще не установлен
apt-get install -y nftables

# Включение и запуск службы nftables
systemctl enable --now nftables

# Ввод порта для перенаправления
read -p "Введите порт для перенаправления трафика с порта 22: " new_port

# Проверка, является ли введенное значение числом
if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: Введено не числовое значение."
    exit 1
fi

# Создание таблицы NAT, если еще не создана
nft list tables | grep -q '^nat$' || nft add table ip nat

# Создание цепочки prerouting, если еще не создана
nft list chains ip nat | grep -q '^prerouting$' || nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; }'

# Удаление старого правила, если существует
nft delete rule ip nat prerouting ip daddr 192.168.100.2 tcp dport 22

# Добавление нового правила перенаправления трафика с порта 22 на указанный порт
nft add rule ip nat prerouting ip daddr 192.168.100.2 tcp dport 22 dnat to 192.168.100.2:$new_port

# Сохранение конфигурации
nft list ruleset | tee /etc/nftables/nftables.nft

# Перезапуск службы nftables для применения конфигурации
systemctl restart nftables

echo "Перенаправление трафика с порта 22 на порт $new_port выполнено успешно."
