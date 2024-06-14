#!/bin/bash

apt-get update && apt-get install -y nftables

systemctl enable --now nftables

nft add table ip nat

nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'

nft add rule ip nat postrouting ip saddr 11.11.11.0/24 oifname "ens33" counter masquerade

nft add rule ip nat postrouting ip saddr 22.22.22.0/24 oifname "ens33" counter masquerade

nft add rule ip nat postrouting ip saddr 33.33.33.0/24 oifname "ens33" counter masquerade

nft list ruleset

nft list ruleset | tail -n8 | tee -a /etc/nftables/nftables.nft

systemctl restart nftables

nft list ruleset