#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Изменение порта SSH в конфигурационном файле
SSH_CONFIG="/etc/ssh/sshd_config"
NEW_PORT=2222

echo "Изменение порта SSH на $NEW_PORT..."
if [ -f "$SSH_CONFIG" ]; then
    sed -i "s/#Port 22/Port $NEW_PORT/g" "$SSH_CONFIG" || error_exit "Не удалось изменить порт в $SSH_CONFIG."
else
    error_exit "Файл $SSH_CONFIG не найден."
fi

# Перезапуск службы sshd
echo "Перезапуск службы sshd..."
systemctl restart sshd || error_exit "Не удалось перезапустить службу sshd."

# Проверка, что служба sshd слушает на новом порту
echo "Проверка, что служба sshd слушает на порту $NEW_PORT..."
if ss -tlpn | grep sshd; then
    echo "Служба sshd успешно слушает на порту $NEW_PORT."
else
    error_exit "Служба sshd не слушает на порту $NEW_PORT."
fi
