#!/bin/bash
NIC_PUBLIC=eth0
NIC_VPN=tap0
NIC_BRIDGE=br-fftr

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

#################################

## INPUT

# TCP/UDP Port 10000
iptables -A INPUT -p TCP --dport 10000 -i $NIC_PUBLIC -j ACCEPT
iptables -A INPUT -p UDP --dport 10000 -i $NIC_PUBLIC -j ACCEPT

# TCP Port 22
iptables -A INPUT -p TCP --dport 22 -i $NIC_PUBLIC -j ACCEPT

# Allow DNS from all devices
iptables -A INPUT -p UDP --dport 53 -i $NIC_PUBLIC -j ACCEPT

# Allow INPUT and OUTPUT Bridge Interface
iptables -A INPUT -i $NIC_BRIDGE -j ACCEPT
iptables -A OUTPUT -o $NIC_BRIDGE -j ACCEPT

## OUTPUT
iptables -A OUTPUT -p UDP -o eth0 --dport 53 -j ACCEPT
iptables -A OUTPUT -p TCP -o eth0 --dport 80 -j ACCEPT
iptables -A OUTPUT -p TCP -o eth0 --dport 443 -j ACCEPT

#################################

# Block all
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
