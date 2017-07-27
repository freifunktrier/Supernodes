#!/bin/sh

# we don't need this skript anymore in our net
exit 0
# can be deleted if system works


#reload sysctl because of https://bugs.launchpad.net/ubuntu/+source/procps/+bug/50093
#TL;DR: sysctl is loaded incompleatly because it's loaded to early in the boot
service procps start

if ! grep -q VPN /etc/iproute2/rt_tables; then
	echo 10 VPN >> /etc/iproute2/rt_tables
fi

#remove rule if it exists to prevent filling the table with dublicates
ip rule del iif br-fftr table VPN
ip -6 rule del iif br-fftr table VPN

#Packets from mesh are routet via VPN, not via main uplink
ip rule add iif br-fftr table VPN
ip -6 rule add iif br-fftr table VPN

#route otherwise unroutable IP-Adresses via VPN and not via main uplink
ip -6 rule add from 2001:bf7:fc00::/44 table VPN
ip rule add from 10.172.0.0/16 table VPN

#172.31.240.0/20 is just pushed to the VPN, rest is routed via 172.31.240.1
#ip route add default via 172.31.240.1 dev tun0 table VPN
#ip route add 172.31.240.0/20 dev tun0 table VPN

#enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

