# Supernodes

We use different typs of Gateways.  
**Glubit** an **Baldur** (Berlin) just have fastd-sessions to all other Gateways but no Client-fastd-sessions.  
**Glubit** an **Baldur** (Berlin) have BGP6-sessions to our 1. Provider.  
**Glubit** an **Baldur** (Berlin) do NAT on IPv4.

**Rustig** and **Kuga** have BGP6-sessions to our 2. Provider and do Client-fastd-sessions as GW04 and GW05 since our gluon 0.14.0 in 2020.  
**Rustig** and **Kuga** do NAT on IPv4 
**Pegol** just does monitoring and firmware-mirroring but no client-fastd-sessions.  

All ohter GWs just do Client-fastd-sessions and forward all traffic to Glubit, Baldur, Rustig or Kuga.  

## Segmentation
**Baldur** and **Glubit** are our only 
- GWs doing tinc 

**Baldur**, **Glubit**, **Rustig** and **Kuga** are
- Batman-Gateways 
- GWs doing NAT
- IPv4-gateways to the internet 
- IPv6-gateways to the internet 
- GWs doing bgp 
- GWs doing bgp6 
- GWs doing DHCP-server
- GWs doing RA
- GWs doing routing between our subnet segments

All other Supernodes just collecting the connections from our fastd-clients.  

On top of this config we add some more interfaces and routings. 

We start with 5 segments and so every GW has 
- 6 fastd services listening on port 10000 - 10005 (Baldur has 10100 - 10105) 
- 6 fastd-connections to every other GW (fvpn fvpn_01 fvpn_02 fvpn_03 fvpn_04 fvpn_05)
- 6 br-fftr - Bridges (br-fftr br-fftr_01 br-fftr_02 br-fftr_03 br-fftr_04 br-fftr_05)
- 6 Batman-interfaces (bat0 bat01 bat02 bat03 bat04 bat05)
- dhcp-Server delivering IPs  from 6 ranges according to the requesting segement







