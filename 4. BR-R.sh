#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

BranchAdmin="branch-admin"
NetworkAdmin="network-admin"
PASSWORD="P@ssw0rd"
BranchComment="Branch admin"
NetworkComment="Network admin"

# Создание пользователя branch-admin
echo "Создание пользователя $BranchAdmin..."
useradd -m -c "$BranchComment" -U "$BranchAdmin" || error_exit "Не удалось создать пользователя $BranchAdmin."

# Установка пароля для branch-admin
echo "Установка пароля для пользователя $BranchAdmin..."
echo "$BranchAdmin:$PASSWORD" | chpasswd || error_exit "Не удалось установить пароль для пользователя $BranchAdmin."

# Создание пользователя network-admin
echo "Создание пользователя $NetworkAdmin..."
useradd -m -c "$NetworkComment" -U "$NetworkAdmin" || error_exit "Не удалось создать пользователя $NetworkAdmin."

# Установка пароля для network-admin
echo "Установка пароля для пользователя $NetworkAdmin..."
echo "$NetworkAdmin:$PASSWORD" | chpasswd || error_exit "Не удалось установить пароль для пользователя $NetworkAdmin."

echo "Пользователи $BranchAdmin и $NetworkAdmin успешно созданы и пароли установлены."

grep admin /etc/passwd
