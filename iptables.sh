#!/bin/bash
NIC_PUBLIC=eth0
NIC_VPN=tun0
NIC_BRIDGE=br-fftr
NIC_IC=icvpn

# Clear and Reset to Defaults
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t mangle -P PREROUTING ACCEPT
iptables -t mangle -P OUTPUT ACCEPT

# Flush all rules
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Erease all non-default chains
iptables -X
iptables -t nat -X
iptables -t mangle -X

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -d 127.0.0.1 -j ACCEPT
iptables -A OUTPUT -s 127.0.0.1 -j ACCEPT

# Established, Related
iptables -A INPUT -p ALL -i $NIC_PUBLIC -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p ALL -o $NIC_PUBLIC -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p ALL -i $NIC_VPN -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p ALL -o $NIC_VPN -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p ALL -i $NIC_IC -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p ALL -o $NIC_IC -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow mesh --> VPN
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_VPN -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1334
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_VPN -j ACCEPT
# Allow existing connections to find their way back
iptables -A FORWARD -i $NIC_VPN -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1334
iptables -A FORWARD -i $NIC_VPN -p ALL -o $NIC_BRIDGE -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow mesh <--> IC
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_IC -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1334
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_IC -j ACCEPT
iptables -A FORWARD -i $NIC_IC -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1334
iptables -A FORWARD -i $NIC_IC -o $NIC_BRIDGE -j ACCEPT

# Allow mesh <--> mesh
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1334
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_BRIDGE -j ACCEPT

# Usefull ICMP-Stuff
for i in destination-unreachable echo-reply echo-request time-exceeded; do
	iptables -A INPUT -p ICMP --icmp-type $i -j ACCEPT
	iptables -A OUTPUT -p ICMP --icmp-type $i -j ACCEPT
done

#################################

## INPUT

# TCP/UDP Port 10000/10001 (fastd)
iptables -A INPUT -p TCP --dport 10000 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p UDP --dport 10000 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p TCP --dport 10001 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p UDP --dport 10001 -i $NIC_PUBLIC -j ACCEPT

# TCP/UDP Port 655 (tinc)
iptables -A INPUT -p TCP --dport 655 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p UDP --dport 655 -i $NIC_PUBLIC -j ACCEPT

# TCP Port 22 (SSH)
iptables -A INPUT -p TCP --dport 22 -i $NIC_PUBLIC -j ACCEPT

# Allow DNS from IC and Mesh
iptables -A INPUT -p UDP --dport 53 -i $NIC_IC -j ACCEPT
iptables -A INPUT -p TCP --dport 53 -i $NIC_IC -j ACCEPT
iptables -A INPUT -p UDP --dport 53 -i $NIC_BRIDGE -j ACCEPT
iptables -A INPUT -p TCP --dport 53 -i $NIC_BRIDGE -j ACCEPT

# Allow HTTP from IC and Mesh
iptables -A INPUT -p UDP --dport 80 -i $NIC_IC -j ACCEPT
iptables -A INPUT -p TCP --dport 80 -i $NIC_IC -j ACCEPT
iptables -A INPUT -p UDP --dport 80 -i $NIC_BRIDGE -j ACCEPT
iptables -A INPUT -p TCP --dport 80 -i $NIC_BRIDGE -j ACCEPT

# Allow INPUT and OUTPUT Bridge Interface
#TODO: remove this rules, add allow rules for established+related connections, ping, speedtest, 80tcp, 53udp/tcp, router-advertisement-zeug, ntp
iptables -A INPUT -i $NIC_BRIDGE -j ACCEPT
iptables -A OUTPUT -o $NIC_BRIDGE -j ACCEPT

#DHCP out to serve our clients
iptables -A INPUT  -p UDP -i $NIC_BRIDGE --sport 68 --dport 67 -j ACCEPT

#allow IC-BGP
iptables -A INPUT -p TCP -i $NIC_IC --dport 179 -j ACCEPT
iptables -A INPUT -p UDP -i $NIC_IC --dport 179 -j ACCEPT

## OUTPUT

#DNS
iptables -A OUTPUT -p UDP -o $NIC_IC --dport 53 -j ACCEPT
iptables -A OUTPUT -p TCP -o $NIC_IC --dport 53 -j ACCEPT
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC --dport 53 -j ACCEPT
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC --dport 53 -j ACCEPT

#DHCP out to serve our clients
iptables -A OUTPUT -p UDP -o $NIC_BRIDGE --sport 67 --dport 68 -j ACCEPT

# allow every TCP/UDP output on public, because tinc will use any port any city decides to use to connect to that city
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC -j ACCEPT
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC -j ACCEPT

# allow IC-BGP
iptables -A OUTPUT -p TCP -o $NIC_IC --dport 179 -j ACCEPT
iptables -A OUTPUT -p UDP -o $NIC_IC --dport 179 -j ACCEPT
#################################

#reject everything that did not match any previous
iptables -A INPUT -j REJECT
iptables -A FORWARD -j REJECT
iptables -A INPUT -j REJECT
# Drop the rest (reject is not possible here and there should be no rest anyway)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

#ipv6
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -P PREROUTING ACCEPT
ip6tables -t nat -P POSTROUTING ACCEPT
ip6tables -t nat -P OUTPUT ACCEPT
ip6tables -t mangle -P PREROUTING ACCEPT
ip6tables -t mangle -P OUTPUT ACCEPT

# Flush all rules
ip6tables -F
ip6tables -t nat -F
ip6tables -t mangle -F

# Erease all non-default chains
ip6tables -X
ip6tables -t nat -X
ip6tables -t mangle -X

#reject traffic to/from routers
for i in $(/root/alfred-json/src/alfred-json -r 158 -z | jq '.[] | {network} | .[] | {addresses} | .[] | .[]' | grep -E -o '2001:bf7:fc0f:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}' | grep -v -F -f /root/Supernodes-dynamic/iptables-whitelist); do
	ip6tables -A INPUT -i $NIC_IC -d $i -j REJECT --reject-with adm-prohibited
	ip6tables -A OUTPUT -o $NIC_IC -s $i -j REJECT --reject-with adm-prohibited
	ip6tables -A FORWARD -i $NIC_IC -d $i -j REJECT --reject-with adm-prohibited
	ip6tables -A FORWARD -o $NIC_IC -s $i -j REJECT --reject-with adm-prohibited
done

ip6tables -A FORWARD -i $NIC_BRIDGE -o $NIC_VPN -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1314
ip6tables -A FORWARD -i $NIC_VPN -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1314
ip6tables -A FORWARD -i $NIC_BRIDGE -o $NIC_IC -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1314
ip6tables -A FORWARD -i $NIC_IC -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1314
ip6tables -A FORWARD -i $NIC_BRIDGE -o $NIC_BRIDGE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1314
