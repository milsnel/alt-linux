#!/bin/bash

set -e

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

apt-get install -y radvd

echo net.ipv6.conf.ens34.accept_ra = 2 >> /etc/net/sysctl.conf

systemctl restart network

cat <<EOF > /etc/radvd.conf 
#NOTE: there is no such thing as a working “by-default” configuration file.
#At least the prefix needs to be specified. Please consult the radud.conf(5)
# man page and/or /usr/share/doc/radud—*/radud.conf example for help.
#
#
#
#
interface ens34
{
    AdvSendAdvert on;
    AdvManagedFlag on;
    AdvOtherConfigFlag on;
    prefix 2000:100::/124
    {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr on;
    };
};
EOF


systemctl restart dhcpd6
systemctl enable --now radvd