#!/bin/bash

apt-get install -y nftables

systemctl enable --now nftables

nft add table inet nat

nft add chain inet nat prerouting '{ type nat hook prerouting priority 0; }'

nft add rule inet nat prerouting ip daddr 172.16.100.2 tcp dport 22 dnat to 192.168.100.2:2222

nft add rule inet nat prerouting ip6 daddr 2001:100::2 tcp dport 22 dnat to [2000:100::2]:2222

nft add chain inet nat postrouting '{ type nat hook postrouting priority 0; }'

nft add rule inet nat postrouting ip saddr 192.168.100.0/26 oifname 'ens33' counter masquerade

nft list ruleset | tail -n 12 | tee -a /etc/nftables/nftables.nft

systemctl restart nftables