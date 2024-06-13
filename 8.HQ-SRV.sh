#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Обновление и установка nftables
echo "Обновление списка пакетов и установка nftables..."
apt-get update && apt-get install -y nftables || error_exit "Не удалось установить nftables."

# Включение и запуск службы nftables
echo "Включение и запуск службы nftables..."
systemctl enable --now nftables || error_exit "Не удалось включить и запустить службу nftables."

# Добавление правил в nftables
echo "Добавление правил в nftables..."
nft add rule inet filter input ip saddr 33.33.33.2 tcp dport 2222 counter drop || error_exit "Не удалось добавить правило для 33.33.33.2."
nft add rule inet filter input ip saddr 44.44.44.0/64 tcp dport 2222 counter drop || error_exit "Не удалось добавить правило для 44.44.44.0/24."
nft add rule inet filter input ip6 saddr 2001:33::2 tcp dport 2222 counter drop || error_exit "Не удалось добавить правило для 2001:33::/64."
nft add rule inet filter input ip6 saddr 2001:44::0/64 tcp dport 2222 counter drop || error_exit "Не удалось добавить правило для 2001:44::/64."

# Удаление существующего файла конфигурации nftables
NFTABLES_CONF="/etc/nftables/nftables.nft"
echo "Удаление существующего файла конфигурации $NFTABLES_CONF..."
rm -f "$NFTABLES_CONF" || error_exit "Не удалось удалить файл $NFTABLES_CONF."

# Создание нового файла конфигурации nftables
echo "Создание нового файла конфигурации $NFTABLES_CONF..."
cat <<EOF > "$NFTABLES_CONF"
#!/usr/sbin/nft -f
# ipv4/ipv6 Simple & Safe Firewall
# you can find examples in /usr/share/nftables/

EOF

# Сохранение текущего набора правил в файл конфигурации
echo "Сохранение текущего набора правил в $NFTABLES_CONF..."
nft list ruleset | tee -a "$NFTABLES_CONF" || error_exit "Не удалось сохранить текущий набор правил в $NFTABLES_CONF."

# Перезапуск службы nftables
echo "Перезапуск службы nftables..."
systemctl restart nftables || error_exit "Не удалось перезапустить службу nftables."

# Показать текущий набор правил
echo "Текущий набор правил nftables:"
nft list ruleset || error_exit "Не удалось получить текущий набор правил nftables."

echo "Скрипт успешно выполнен."
