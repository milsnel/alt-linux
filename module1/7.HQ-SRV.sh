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

# Ввод нового порта для SSH
read -p "Введите новый порт для SSH: " NEW_PORT

# Проверка, является ли введенное значение числом
if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
    error_exit "Ошибка: Введено не числовое значение."
fi

# Изменение порта SSH в конфигурационном файле
SSH_CONFIG="/etc/openssh/sshd_config"

echo "Изменение порта SSH на $NEW_PORT..."
if [ -f "$SSH_CONFIG" ]; then
    if grep -q "^#Port 22" "$SSH_CONFIG"; then
        sed -i "s/^#Port 22/Port $NEW_PORT/" "$SSH_CONFIG" || error_exit "Не удалось изменить порт в $SSH_CONFIG."
    elif grep -q "^Port 22" "$SSH_CONFIG"; then
        sed -i "s/^Port 22/Port $NEW_PORT/" "$SSH_CONFIG" || error_exit "Не удалось изменить порт в $SSH_CONFIG."
    else
        echo "Port $NEW_PORT" >> "$SSH_CONFIG" || error_exit "Не удалось добавить порт в $SSH_CONFIG."
    fi
else
    error_exit "Файл $SSH_CONFIG не найден."
fi

# Перезапуск службы sshd
echo "Перезапуск службы sshd..."
systemctl restart sshd || error_exit "Не удалось перезапустить службу sshd."

# Проверка, что служба sshd слушает на новом порту
echo "Проверка, что служба sshd слушает на порту $NEW_PORT..."
if ss -tlpn | grep ":$NEW_PORT"; then
    echo "Служба sshd успешно слушает на порту $NEW_PORT."
else
    error_exit "Служба sshd не слушает на порту $NEW_PORT."
fi
