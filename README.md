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
- GWs doing DHCP-Servcer
- GWs doing RA

All other Supernodes just collecting the connections from our fastd-clients.  

On top of this config we add some interfaces and Routings. 
We start with 5 segments and so very GW has 5 fastd-connections to every other GW. 







