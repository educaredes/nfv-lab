#!/bin/bash
export OSMNS  # needs to be defined in calling shell
export VACCESS=$VACC1
export VCPE=$VCPE1

# call vcpe_start <vnf_tunnel_ip> <home_tunnel_ip> <vcpe_private_ip> <vcpe_public_ip> <vcpe_gw> <dhcpd_conf_file>
./vcpe_start.sh 10.255.0.1 10.255.0.2 192.168.255.1 10.100.1.1 10.100.1.254 conf/dhcpd-1.conf
