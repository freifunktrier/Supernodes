#!/bin/sh
service isc-dhcp-server start
batctl gw server
birdc6 enable radv1
cd /root/Supernodes/configs/$(hostname)
sed -E 's/^#? *(.*) #traffic off marker/# \1 #traffic off marker/;s/^#? *(.*) #traffic on marker/  \1 #traffic on marker/' bird6.conf > bird6.conf.new
sed -E 's/^#? *(.*) #traffic off marker/# \1 #traffic off marker/;s/^#? *(.*) #traffic on marker/  \1 #traffic on marker/' bird.conf > bird.conf.new
mv bird6.conf.new bird6.conf
mv bird.conf.new bird.conf
birdc6 configure
birdc configure
