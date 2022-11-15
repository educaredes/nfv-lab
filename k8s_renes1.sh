#!/bin/bash
USAGE="
Usage:
    
k8s_renes1.sh <access_deployment_id> <cpe_deployment_id>
    being:
        <access_deployment_id>: deployment_id of the access vnf
        <cpe_deployment_id>: deployment_id of the cpd vnf
"

if [[ $# -ne 2 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi

export OSMNS  # needs to be defined in calling shell
export VACC="deploy/$1"
export VCPE="deploy/$2"

echo $VACC
echo $VCPE

# HOMETUNIP: the ip address for the home side of the tunnel
export HOMETUNIP="10.255.0.2"

# VNFTUNIP: the ip address for the vnf side of the tunnel
export VNFTUNIP="10.255.0.1"

# VCPEPUBIP: the public ip address for the vcpe
export VCPEPUBIP="10.100.1.1"

# VCPEGW: the default gateway for the vcpe
export VCPEGW="10.100.1.254"

./k8s_renes_start.sh 
