#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

Admin="admin"
NetworkAdmin="network-admin"
PASSWORD="P@ssw0rd"
AdminComment="Admin"
NetworkComment="Network admin"

# Создание пользователя admin
echo "Создание пользователя $Admin..."
useradd -m -c "$BranchComment" -U "$Admin" || error_exit "Не удалось создать пользователя $Admin."

# Установка пароля для admin
echo "Установка пароля для пользователя $Admin..."
echo "$Admin:$PASSWORD" | chpasswd || error_exit "Не удалось установить пароль для пользователя $Admin."

# Создание пользователя network-admin
echo "Создание пользователя $NetworkAdmin..."
useradd -m -c "$NetworkComment" -U "$NetworkAdmin" || error_exit "Не удалось создать пользователя $NetworkAdmin."

# Установка пароля для network-admin
echo "Установка пароля для пользователя $NetworkAdmin..."
echo "$NetworkAdmin:$PASSWORD" | chpasswd || error_exit "Не удалось установить пароль для пользователя $NetworkAdmin."

echo "Пользователи $Admin и $NetworkAdmin успешно созданы и пароли установлены."

grep admin /etc/passwd
