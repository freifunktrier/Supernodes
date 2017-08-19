# Supernodes

Our aim is to have our network cut into different subnets. Therefore we planed our IP-Ranges according to GW-Datentabelle.ods  

This branch works out the config for this.


## Segmentation
This branch is based on the facts: 
Baldur and Glubit are our only 
- Batman-Gateways 
- GWs doing NAT
- IPv4-Gateways to the Internet 
- GWs doing tinc 
- GWs doing bgp 
- GWs doing bgp6 
- GWs doing DHCP-Server (Range 10.172.0.0 - 10.172.15.255)
- GWs doing RA
- GWs doing routing between our subnet segments

All other Supernodes just collecting the connections from our fastd-clients.  

On top of this config we add some more interfaces and routings. 

We start with 5 additional segments and so every GW has 
- 6 fastd services listening on port 10000 - 10005 (Baldur has 10100) 
- 6 fastd-connections to every other GW (fvpn fvpn_01 fvpn_02 fvpn_03 fvpn_04 fvpn_05)
- 6 br-fftr - Bridges (br-fftr br-fftr_01 br-fftr_02 br-fftr_03 br-fftr_04 br-fftr_05)
- 6 Batman-interfaces (bat0 bat01 bat02 bat03 bat04 bat05)
- dhcp-Server (only on Baldur and Glubit) delivering IPs  from 6 ranges according to the requesting segement

Our next gluon will add the ability for connection to our GWs on the additional ports. Moving the fastd-keys of nodes into the new segments makes the connecting node only part of the segment his key is found valid for.







