#!/bin/sh

if ! grep -q VPN /etc/iproute2/rt_tables; then
	echo 10 VPN >> /etc/iproute2/rt_tables
fi

if ! grep -q anycast /etc/iproute2/rt_tables; then
	echo 11 anycast >> /etc/iproute2/rt_tables
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

#the anycast-mesh-ip is routed via the anycast-mac
ip rule add from 10.172.0.10/32 table anycast
ip route add table anycast 10.172.0.0/16 dev fftr-gw-anycast

#172.31.240.0/20 is just pushed to the VPN, rest is routed via 172.31.240.1
#ip route add default via 172.31.240.1 dev tun0 table VPN
#ip route add 172.31.240.0/20 dev tun0 table VPN

#enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

#enable correct anycast-arp-handling
sysctl -w net.ipv4.conf.all.arp_filter=1

