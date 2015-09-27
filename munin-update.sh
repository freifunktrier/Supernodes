#!/bin/bash
mkdir /tmp/munin-plugins
{ cat /root/Supernodes/legacy-munin-nodes; /root/alfred-json/src/alfred-json -r 158 -z | jq '.[] | select(.supernode.statistics == true) | {network} | .[] | {mac} | .[]' | grep -E -o "[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}"; } | while read i; do
	echo "Processing $i"
        for j in clients loadavg memory processes traffic uptime
          do ln -s /root/munin-routerinfo/alfredmunin.zsh /tmp/munin-plugins/alfred_${i}_${j}
        done

	echo >> /etc/munin/munin-conf.d/alfred.conf.tmp
	echo "[localhost.localdomain;${i//:/}]" >> /etc/munin/munin-conf.d/alfred.conf.tmp
	echo "    address 127.0.0.1" >> /etc/munin/munin-conf.d/alfred.conf.tmp
done
rm /etc/munin/plugins/alfred_*
mv /tmp/munin-plugins/* /etc/munin/plugins/
rmdir /tmp/munin-plugins
mv /etc/munin/munin-conf.d/alfred.conf.tmp /etc/munin/munin-conf.d/alfred.conf
service munin-node reload
