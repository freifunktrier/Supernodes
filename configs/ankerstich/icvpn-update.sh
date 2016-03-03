#!/bin/sh

DATADIR=/var/lib/icvpn-meta

cd /etc/tinc/icvpn
git pull -q

cd "$DATADIR"
git pull -q

/opt/icvpn-scripts/mkbgp -4 -f bird -d peers -s "$DATADIR" -x trier -t berlin:uplink_peers | sed 's/protocol bgp berlin2 from uplink_peers {/protocol bgp berlin2 from prefered_uplink_peers {/' > /etc/bird/bird.d/icvpn.conf
/opt/icvpn-scripts/mkroa -4 -f bird -s "$DATADIR" > /etc/bird/roa4.con
birdc configure

/opt/icvpn-scripts/mkbgp -6 -f bird -d peers -s "$DATADIR" -x trier -t berlin:uplink_peers | sed 's/protocol bgp berlin2 from uplink_peers {/protocol bgp berlin2 from prefered_uplink_peers {/' > /etc/bird/bird6.d/icvpn.conf
/opt/icvpn-scripts/mkroa -6 -f bird -s "$DATADIR" > /etc/bird/roa6.con
birdc6 configure

/opt/icvpn-scripts/mkdns -f bind -s "$DATADIR" -x trier > /etc/bind/ic.conf
service bind9 reload

/opt/icvpn-scripts/mksmokeping -f SmokePing -s "$DATADIR" > /etc/smokeping/config.d/icvpn
service smokeping reload