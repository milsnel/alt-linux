#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

Admin="admin"
PASSWORD="P@ssw0rd"
AdminComment="Admin"

# Создание пользователя admin
echo "Создание пользователя $Admin..."
useradd -m -c "$AdminComment" -U "$Admin" || error_exit "Не удалось создать пользователя $Admin."

# Установка пароля для admin
echo "Установка пароля для пользователя $Admin..."
echo "$Admin:$PASSWORD" | chpasswd || error_exit "Не удалось установить пароль для пользователя $Admin."

echo "Пользователь $Admin успешно создан и пароль установлен."

grep admin /etc/passwd
