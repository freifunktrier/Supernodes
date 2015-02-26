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

# Allow mesh --> VPN
iptables -A FORWARD -i $NIC_BRIDGE -o $NIC_VPN -j ACCEPT
# Allow existing connections to find their way back
iptables -A FORWARD -i $NIC_VPN -p ALL -o $NIC_BRIDGE -m state --state ESTABLISHED,RELATED -j ACCEPT

# Usefull ICMP-Stuff
for i in destination-unreachable echo-reply echo-request time-exceeded; do
	iptables -A FORWARD -p ICMP --icmp-type $i -j ACCEPT
	iptables -A INPUT -p ICMP --icmp-type $i -j ACCEPT
	iptables -A OUTPUT -p ICMP --icmp-type $i -j ACCEPT
done

#################################

## INPUT

# TCP/UDP Port 10000 (fastd)
iptables -A INPUT -p TCP --dport 10000 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p UDP --dport 10000 -i $NIC_PUBLIC -j ACCEPT

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

# Allow INPUT and OUTPUT Bridge Interface
iptables -A INPUT -i $NIC_BRIDGE -j ACCEPT
iptables -A OUTPUT -o $NIC_BRIDGE -j ACCEPT

#DHCP out to serve our clients
iptables -A INPUT  -p UDP -i $NIC_BRIDGE --sport 68 --dport 67 -j ACCEPT

#allow IC-BGP
iptables -A INPUT -p TCP -i $NIC_IC --dport 179 -j ACCEPT
iptables -A INPUT -p UDP -i $NIC_IC --dport 179 -j ACCEPT

## OUTPUT

#DNS
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC --dport 53 -j ACCEPT
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC --dport 53 -j ACCEPT

#HTTP(S) for Updates and Git
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC --dport 80 -j ACCEPT
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC --dport 443 -j ACCEPT

#OpenVPN uplink
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC --dport 1194 -j ACCEPT
#NTP uplink
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC --dport 123  -d 192.168.101.49 -j ACCEPT

#DHCP out to serve our clients
iptables -A OUTPUT -p UDP -o $NIC_BRIDGE --sport 67 --dport 68 -j ACCEPT

#DHCP for our uplink
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC --sport 68 --dport 67 -j ACCEPT

# allow every TCP/UDP output, because tinc will use any port any city decides to use to connect to that city
iptables -A OUTPUT -p TCP -o $NIC_PUBLIC -j ACCEPT
iptables -A OUTPUT -p UDP -o $NIC_PUBLIC -j ACCEPT

# allow IC-BGP
iptables -A OUTPUT -p TCP -o $NIC_IC --dport 179 -j ACCEPT
iptables -A OUTPUT -p UDP -o $NIC_IC --dport 179 -j ACCEPT
#################################

# Reject all (we do NOT block. block is rude)
iptables -P INPUT REJECT
iptables -P FORWARD REJECT
iptables -P OUTPUT REJECT
