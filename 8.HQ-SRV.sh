#!/bin/bash

set -e  # Прекращение работы скрипта при ошибке

error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Обновление и установка nftables
echo "Бля я не сделал..."
