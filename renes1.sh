#!/bin/bash
export OSMNS  # needs to be defined in calling shell
export VACCESS="deploy/$VACC1"
export VCPE="deploy/$VCPE1"

# call renes_start <vnf_tunnel_ip> <home_tunnel_ip> <vcpe_private_ip> <vcpe_public_ip> <vcpe_gw>
./renes_start.sh 10.255.0.1 10.255.0.2 192.168.255.1 10.100.1.1 10.100.1.254
