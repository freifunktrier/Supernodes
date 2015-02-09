#!/bin/sh

if ! grep -q VPN /etc/iproute2/rt_tables; then
	echo 1 VPN >> /etc/iproute2/rt_tables

	#Packets from mesh are routet via VPN, not via main uplink
	ip rule add iif br-fftr table VPN
fi

#172.31.240.0/20 is just pushed to the VPN, rest is routed via 172.31.240.1
ip route add default via 172.31.240.1 dev tun0 table VPN
ip route add 172.31.240.0/20 dev tun0 table VPN

#enable forwarding
echo 1 | tee /proc/sys/net/ipv4/ip_forward
