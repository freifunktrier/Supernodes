#!/bin/bash
NIC_PUBLIC=eth0
NIC_VPN=tun0
NIC_BRIDGE=br-fftr
NIC_IC=icvpn
ALFRED_JSON=""
if [ -e "/var/lib/Supernodes/configs/$(hostname)/iptables" ]; then
	. "/var/lib/Supernodes/configs/$(hostname)/iptables"
fi

if [ ! -f "$ALFRED_JSON" ]; then
	ALFRED_JSON="/root/alfred-json/src/alfred-json"
fi

if [ ! -f "$ALFRED_JSON" ]; then
	ALFRED_JSON="/usr/local/src/alfred-json/build/src/alfred-json"
fi

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

#Thank you http://www.semicomplete.com/blog/geekery/atomic-iptables-changes-and-not-dropping-packets.html
formatrule() {
  while [ $# -gt 0 ] ; do
    # If the current arg has a space in it, output "arg"
    #if echo "$1" | grep -q ' '  ; then
      echo -n "\"$1\""
    #else
    #  echo -n "$1"
    #fi
    [ $# -gt 1 ] && echo -n " "
    shift
  done
  echo
}

rulefile="$(mktemp)"
counterfile="$(mktemp)"
echo "
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
" > $rulefile
#disable conntrack für everything exept 10.172.0.8 - 10.172.0.15
echo "
:notrack-helper-PREROUTING - [0:0]
:notrack-helper-OUTPUT - [0:0]
-A PREROUTING -i icvpn -j notrack-helper-PREROUTING
-A PREROUTING -i br-fftr -j notrack-helper-PREROUTING
-A notrack-helper-PREROUTING -s 10.172.0.0/27 -j RETURN
-A notrack-helper-PREROUTING -d 10.172.0.0/27 -j RETURN
-A notrack-helper-PREROUTING -s 10.207.0.216/29 -j RETURN
-A notrack-helper-PREROUTING -d 10.207.0.216/29 -j RETURN
-A notrack-helper-PREROUTING -s 10.207.0.93/32 -j RETURN
-A notrack-helper-PREROUTING -d 10.207.0.93/32 -j RETURN
-A notrack-helper-PREROUTING -j NOTRACK

-A OUTPUT -o icvpn -j notrack-helper-OUTPUT
-A OUTPUT -o br-fftr -j notrack-helper-OUTPUT
-A notrack-helper-OUTPUT -s 10.172.0.0/27 -j RETURN
-A notrack-helper-OUTPUT -d 10.172.0.0/27 -j RETURN
-A notrack-helper-OUTPUT -s 10.207.0.216/29 -j RETURN
-A notrack-helper-OUTPUT -d 10.207.0.216/29 -j RETURN
-A notrack-helper-OUTPUT -s 10.207.0.93/32 -j RETURN
-A notrack-helper-OUTPUT -d 10.207.0.93/32 -j RETURN
-A notrack-helper-OUTPUT -j NOTRACK
COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
" >> $rulefile
addrule() {
	formatrule "$@" >> $rulefile
}

rulefile6="$(mktemp)"
echo "
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -j NOTRACK
-A OUTPUT -j NOTRACK
COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT

*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
" >> $rulefile6
addrule6() {
	formatrule "$@" >> $rulefile6
}


# Clear and Reset to Defaults
#addrule -P INPUT ACCEPT
#addrule -P FORWARD ACCEPT
#addrule -P OUTPUT ACCEPT
#addrule -t nat -P PREROUTING ACCEPT
#addrule -t nat -P POSTROUTING ACCEPT
#addrule -t nat -P OUTPUT ACCEPT
#addrule -t mangle -P PREROUTING ACCEPT
#addrule -t mangle -P OUTPUT ACCEPT

# Flush all rules
#addrule -F
#addrule -t nat -F
#addrule -t mangle -F

# Erease all non-default chains
#addrule -X
#addrule -t nat -X
#addrule -t mangle -X

# Loopback
addrule -A INPUT -i lo -j ACCEPT
addrule -A OUTPUT -o lo -j ACCEPT
addrule -A INPUT -d 127.0.0.1 -j ACCEPT
addrule -A OUTPUT -s 127.0.0.1 -j ACCEPT

iptables-save -c > $counterfile

echo -n "$(grep "INPUT.*ACC-fastd" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A INPUT  -i $NIC_PUBLIC -p UDP -m multiport --destination-ports 10000:10015,1723 -m comment --comment "ACC-fastd"
echo -n "$(grep "OUTPUT.*ACC-fastd" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A OUTPUT -o $NIC_PUBLIC -p UDP -m multiport --source-ports      10000:10015,1723 -m comment --comment "ACC-fastd"

echo -n "$(grep "INPUT.*ACC-tincudp" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A INPUT  -i $NIC_PUBLIC -p UDP --destination-port 655 -m comment --comment "ACC-tincudp"
echo -n "$(grep "OUTPUT.*ACC-tincudp" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A OUTPUT -o $NIC_PUBLIC -p UDP --source-port      655 -m comment --comment "ACC-tincudp"

echo -n "$(grep "INPUT.*ACC-tinctcp" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A INPUT  -i $NIC_PUBLIC -p TCP --destination-port 655 -m comment --comment "ACC-tinctcp"
echo -n "$(grep "OUTPUT.*ACC-tinctcp" $counterfile | grep -o "\[.*\]") " >> $rulefile
addrule -A OUTPUT -o $NIC_PUBLIC -p TCP --source-port      655 -m comment --comment "ACC-tinctcp"

rm $counterfile

# Established, Related
addrule -A INPUT -p ALL -i $NIC_PUBLIC -m state --state ESTABLISHED,RELATED -j ACCEPT
addrule -A OUTPUT -p ALL -o $NIC_PUBLIC -m state --state ESTABLISHED,RELATED -j ACCEPT

addrule -A INPUT -p ALL -i $NIC_VPN -m state --state ESTABLISHED,RELATED -j ACCEPT
addrule -A OUTPUT -p ALL -o $NIC_VPN -m state --state ESTABLISHED,RELATED -j ACCEPT

addrule -A INPUT -p ALL -i $NIC_IC -m state --state ESTABLISHED,RELATED -j ACCEPT
addrule -A OUTPUT -p ALL -o $NIC_IC -m state --state ESTABLISHED,RELATED -j ACCEPT


# Usefull ICMP-Stuff
for i in destination-unreachable echo-reply echo-request time-exceeded; do
	addrule -A INPUT -p ICMP --icmp-type $i -j ACCEPT
	addrule -A OUTPUT -p ICMP --icmp-type $i -j ACCEPT
done

#################################

## INPUT

# TCP/UDP Port 10000/10001/10100/1723 (fastd)
addrule -A INPUT -p TCP --dport 10000:10015 -i $NIC_PUBLIC -j ACCEPT
addrule -A INPUT -p UDP --dport 10000:10015 -i $NIC_PUBLIC -j ACCEPT
addrule -A INPUT -p TCP --dport 10100 -i $NIC_PUBLIC -j ACCEPT
addrule -A INPUT -p UDP --dport 10100 -i $NIC_PUBLIC -j ACCEPT
addrule -A INPUT -p TCP --dport 1723 -i $NIC_PUBLIC -j ACCEPT
addrule -A INPUT -p UDP --dport 1723 -i $NIC_PUBLIC -j ACCEPT
# for neso who has fastd also on port 80:
addrule -A INPUT -p UDP --dport 80 -i $NIC_PUBLIC -j ACCEPT

# TCP/UDP Port 655 (tinc) NO tinc anymore
#addrule -A INPUT -p TCP --dport 655 -i $NIC_PUBLIC -j ACCEPT
#addrule -A INPUT -p UDP --dport 655 -i $NIC_PUBLIC -j ACCEPT
#addrule -A INPUT -p TCP --dport 656 -i $NIC_PUBLIC -j ACCEPT
#addrule -A INPUT -p UDP --dport 656 -i $NIC_PUBLIC -j ACCEPT
#addrule -A INPUT -p TCP --dport 755 -i $NIC_PUBLIC -j ACCEPT
#addrule -A INPUT -p UDP --dport 755 -i $NIC_PUBLIC -j ACCEPT

# TCP Port 22 (SSH)
addrule -A INPUT -p TCP --dport 22 -i $NIC_PUBLIC -j ACCEPT

# Allow DNS from IC and Mesh
addrule -A INPUT -p UDP --dport 53 -i $NIC_IC -j ACCEPT
addrule -A INPUT -p TCP --dport 53 -i $NIC_IC -j ACCEPT
addrule -A INPUT -p UDP --dport 53 -i $NIC_BRIDGE -j ACCEPT
addrule -A INPUT -p TCP --dport 53 -i $NIC_BRIDGE -j ACCEPT

# Allow HTTP from IC and Mesh
addrule -A INPUT -p UDP --dport 80 -i $NIC_IC -j ACCEPT
addrule -A INPUT -p TCP --dport 80 -i $NIC_IC -j ACCEPT
addrule -A INPUT -p UDP --dport 80 -i $NIC_BRIDGE -j ACCEPT
addrule -A INPUT -p TCP --dport 80 -i $NIC_BRIDGE -j ACCEPT

addrule -A INPUT -p TCP --dport 443 -i $NIC_IC -j ACCEPT
addrule -A INPUT -p TCP --dport 443 -i $NIC_BRIDGE -j ACCEPT

# Allow INPUT and OUTPUT Bridge Interface
#TODO: remove this rules, add allow rules for established+related connections, ping, speedtest, 80tcp, 53udp/tcp, router-advertisement-zeug, ntp
addrule -A INPUT -i $NIC_BRIDGE -j ACCEPT
addrule -A OUTPUT -o $NIC_BRIDGE -j ACCEPT

#DHCP out to serve our clients
addrule -A INPUT  -p UDP -i $NIC_BRIDGE --sport 68 --dport 67 -j ACCEPT

#allow IC-BGP
addrule -A INPUT -p TCP -i $NIC_IC --dport 179 -j ACCEPT
addrule -A INPUT -p UDP -i $NIC_IC --dport 179 -j ACCEPT

#allow 6in4
addrule -A INPUT -p ipv6 -i $NIC_PUBLIC -j ACCEPT
## OUTPUT

#DNS
addrule -A OUTPUT -p UDP -o $NIC_IC --dport 53 -j ACCEPT
addrule -A OUTPUT -p TCP -o $NIC_IC --dport 53 -j ACCEPT
addrule -A OUTPUT -p UDP -o $NIC_PUBLIC --dport 53 -j ACCEPT
addrule -A OUTPUT -p TCP -o $NIC_PUBLIC --dport 53 -j ACCEPT

#DHCP out to serve our clients
addrule -A OUTPUT -p UDP -o $NIC_BRIDGE --sport 67 --dport 68 -j ACCEPT

# allow every TCP/UDP output on public, because tinc will use any port any city decides to use to connect to that city
addrule -A OUTPUT -p TCP -o $NIC_PUBLIC -j ACCEPT
addrule -A OUTPUT -p UDP -o $NIC_PUBLIC -j ACCEPT

# allow IC-BGP
addrule -A OUTPUT -p TCP -o $NIC_IC --dport 179 -j ACCEPT
addrule -A OUTPUT -p UDP -o $NIC_IC --dport 179 -j ACCEPT

#allow 6in4
addrule -A OUTPUT -p ipv6 -o $NIC_PUBLIC -j ACCEPT

#allow monotone
addrule -A OUTPUT -p TCP --dport 4691 -j ACCEPT

#allow GPG-Keyserver for ansible idempotenz
addrule -A OUTPUT -p TCP --dport 11371 -j ACCEPT

#################################

#reject everything that did not match any previous
addrule -A INPUT -j REJECT
addrule -A FORWARD -j REJECT
addrule -A OUTPUT -j REJECT
# Drop the rest (reject is not possible here and there should be no rest anyway)
addrule -P INPUT DROP
addrule -P FORWARD DROP
addrule -P OUTPUT DROP

echo "COMMIT" >> $rulefile
if iptables-restore -c -t $rulefile ; then
  echo "iptables restore test successful, applying rules..."
  iptables-restore -c -v $rulefile
  rm $rulefile
else
  echo "iptables test failed. Rule file:" >&2
  echo "---" >&2
  cat $rulefile >&2
  rm $rulefile
  exit 1
fi

#ipv6
#addrule6 -P INPUT ACCEPT
#addrule6 -P FORWARD ACCEPT
#addrule6 -P OUTPUT ACCEPT
#addrule6 -t nat -P PREROUTING ACCEPT
#addrule6 -t nat -P POSTROUTING ACCEPT
#addrule6 -t nat -P OUTPUT ACCEPT
#addrule6 -t mangle -P PREROUTING ACCEPT
#addrule6 -t mangle -P OUTPUT ACCEPT

# Flush all rules
#addrule6 -F
#addrule6 -t nat -F
#addrule6 -t mangle -F

# Erease all non-default chains
#addrule6 -X
#addrule6 -t nat -X
#addrule6 -t mangle -X

#reject traffic to/from routers
addrule6 -A FORWARD -j REJECT --reject-with adm-prohibited

ip6tables-save -c > $counterfile

echo -n "$(grep "INPUT.*ACC-fastd" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A INPUT  -i $NIC_PUBLIC -p UDP -m multiport --destination-ports 10000:10015,1723 -m comment --comment "ACC-fastd"
echo -n "$(grep "OUTPUT.*ACC-fastd" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A OUTPUT -o $NIC_PUBLIC -p UDP -m multiport --source-ports      10000:10015,1723 -m comment --comment "ACC-fastd"

echo -n "$(grep "INPUT.*ACC-tincudp" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A INPUT  -i $NIC_PUBLIC -p UDP --destination-port 655 -m comment --comment "ACC-tincudp"
echo -n "$(grep "OUTPUT.*ACC-tincudp" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A OUTPUT -o $NIC_PUBLIC -p UDP --source-port      655 -m comment --comment "ACC-tincudp"

echo -n "$(grep "INPUT.*ACC-tinctcp" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A INPUT  -i $NIC_PUBLIC -p TCP --destination-port 655 -m comment --comment "ACC-tinctcp"
echo -n "$(grep "OUTPUT.*ACC-tinctcp" $counterfile | grep -o "\[.*\]") " >> $rulefile6
addrule6 -A OUTPUT -o $NIC_PUBLIC -p TCP --source-port      655 -m comment --comment "ACC-tinctcp"

rm $counterfile

echo "COMMIT" >> $rulefile6
if ip6tables-restore -c -t $rulefile6 ; then
  echo "ip6tables restore test successful, applying rules..."
  ip6tables-restore -c -v $rulefile6
  rm $rulefile6
else
  echo "ip6tables test failed. Rule file:" >&2
  echo "---" >&2
  cat $rulefile6 >&2
  rm $rulefile6
  exit 1
fi

