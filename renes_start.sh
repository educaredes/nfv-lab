#!/bin/bash

USAGE="
Usage:
    
renes_start <vnf_tunnel_ip> <home_tunnel_ip> <vcpe_private_ip> <vcpe_public_ip> <vcpe_gw> <dhcpd_conf_file>
    being:
        <vnf_tunnel_ip>: the ip address for the vnf side of the tunnel
        <home_tunnel_ip>: the ip address for the home side of the tunnel
        <vcpe_private_ip>: the private ip address for the vcpe
        <vcpe_public_ip>: the public ip address for the vcpe 
        <vcpe_gw>: the default gateway for the vcpe
"

if [[ $# -ne 5 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi

set -u # to verify variables are defined
: $OSMNS
: $VACCESS
: $VCPE

VNFTUNIP="$1"
HOMETUNIP="$2"
VCPEPRIVIP="$3"
VCPEPUBIP="$4"
VCPEGW="$5"

## 1. Obtener IPs de las VNFs
echo "## 1. Obtener IPs de las VNFs"
IPACCESS=`microk8s kubectl exec -n $OSMNS $VACCESS -- hostname -I | awk '{print $1}'`
echo "IPACCESS = $IPACCESS"

IPCPE=`microk8s kubectl exec -n $OSMNS $VCPE -- hostname -I | awk '{print $1}'`
echo "IPCPE = $IPCPE"


## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF"
microk8s kubectl exec -n $OSMNS $VACCESS -- service openvswitch-switch start
microk8s kubectl exec -n $OSMNS $VCPE -- service openvswitch-switch start

## 3. En VNF:vclass agregar un bridge y asociar interfaces
echo "## 3. En VNF:vclass agregar un bridge y asociar interfaces"
microk8s kubectl exec -n $OSMNS $VACCESS -- ovs-vsctl add-br brint
microk8s kubectl exec -n $OSMNS $VACCESS -- ifconfig net1 $VNFTUNIP/24
microk8s kubectl exec -n $OSMNS $VACCESS -- ovs-vsctl add-port brint vxlanacc -- set interface vxlanacc type=vxlan options:remote_ip=$HOMETUNIP options:key=inet options:dst_port=8742
microk8s kubectl exec -n $OSMNS $VACCESS -- ovs-vsctl add-port brint vxlanint -- set interface vxlanint type=vxlan options:remote_ip=$IPCPE options:key=inet options:dst_port=8742
microk8s kubectl exec -n $OSMNS $VACCESS -- ip route add $IPCPE/32 via 169.254.1.1

## 4. En VNF:vcpe agregar un bridge y asociar interfaces
echo "## 4. En VNF:vcpe agregar un bridge y asociar interfaces"
microk8s kubectl exec -n $OSMNS $VCPE -- ovs-vsctl add-br brint
microk8s kubectl exec -n $OSMNS $VCPE -- ifconfig brint $VCPEPRIVIP/24
microk8s kubectl exec -n $OSMNS $VCPE -- ovs-vsctl add-port brint vxlanint -- set interface vxlanint type=vxlan options:remote_ip=$IPACCESS options:key=inet options:dst_port=8742
microk8s kubectl exec -n $OSMNS $VCPE -- ifconfig brint mtu 1400
microk8s kubectl exec -n $OSMNS $VCPE -- ip route add $IPACCESS/32 via 169.254.1.1

## 5. En VNF:vcpe asignar dirección IP a interfaz de salida
echo "## 5. En VNF:vcpe asignar dirección IP a interfaz de salida"
microk8s kubectl exec -n $OSMNS $VCPE -- ifconfig net1 $VCPEPUBIP/24
microk8s kubectl exec -n $OSMNS $VCPE -- ip route del 0.0.0.0/0 via 169.254.1.1
microk8s kubectl exec -n $OSMNS $VCPE -- ip route add 0.0.0.0/0 via $VCPEGW

## 6. Iniciar Servidor DHCP
echo "## 6. Iniciar Servidor DHCP"
microk8s kubectl exec -n $OSMNS $VCPE -- sed -i 's/homeint/brint/' /etc/default/isc-dhcp-server
microk8s kubectl exec -n $OSMNS $VCPE -- service isc-dhcp-server restart
sleep 10

## 7. En VNF:vcpe activar NAT para dar salida a Internet
echo "## 7. En VNF:vcpe activar NAT para dar salida a Internet"
microk8s kubectl exec -n $OSMNS $VCPE -- /usr/bin/vnx_config_nat brint net1

