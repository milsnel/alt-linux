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

# Список IP-адресов для блокировки
DENY_USERS="33.33.33.2 2001:33::2 44.44.44.2 2001:44::2 55.55.55.2 2001:55::2"

# Путь к конфигурационному файлу SSH
SSH_CONFIG="/etc/openssh/sshd_config"

# Проверка существования файла конфигурации
if [ ! -f "$SSH_CONFIG" ]; then
    error_exit "Файл $SSH_CONFIG не найден."
fi

# Создание резервной копии конфигурационного файла
cp "$SSH_CONFIG" "${SSH_CONFIG}.bak" || error_exit "Не удалось создать резервную копию файла $SSH_CONFIG."

# Добавление IP-адресов в DenyUsers
echo "Добавление IP-адресов в DenyUsers..."
for ip in $DENY_USERS; do
    if grep -q "^DenyUsers.*$ip" "$SSH_CONFIG"; then
        echo "IP-адрес $ip уже присутствует в DenyUsers."
    else
        sed -i "/^DenyUsers/ s/$/ $ip/" "$SSH_CONFIG" || {
            # Если строка DenyUsers не найдена, добавляем новую строку
            echo "DenyUsers $ip" >> "$SSH_CONFIG"
        }
    fi
done

# Перезапуск службы sshd
echo "Перезапуск службы sshd..."
systemctl restart sshd || error_exit "Не удалось перезапустить службу sshd."

echo "IP-адреса успешно добавлены в DenyUsers и служба sshd перезапущена."
