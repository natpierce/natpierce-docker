#!/bin/sh

if [ "$iptables_mode" = "nftables" ]; then
    /usr/sbin/iptables-nft "$@"
elif [ "$iptables_mode" = "legacy" ]; then
    /usr/sbin/iptables-legacy "$@"
else
    /usr/sbin/iptables "$@"
fi