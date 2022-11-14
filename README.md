# nfv-lab
Repository for NFV lab with OSM MANO.
It contains a helm-repository, check out the [index.yaml](index.yaml)

## Scenario
![scenario detail](doc/nfv-lab-figura4.drawio.png)

## Quick testing guide
1. Launch the machines RDSV-OSM and RDSV-K8S
2. On both machines open a terminal, clone the repository and change to the folder nfv-lab

```
cd Desktop
git clone https://github.com/educaredes/nfv-lab.git
cd nfv-lab
```

3. On RDSV-K8S, start the VNX scenarios

```
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
```

4. On RDSV-OSM, from the Desktop (graphically)
- access the package folder nfv-lab/pck
- start Firefox to access OSM at localhost (admin/admin)
- onboard the VNFs accessknf_vnfd.tar.gz and cpeknf_vnfd.tar.gz
- onboard the NS renes_ns.tar.gz

5. On RDSV-OSM, from the terminal instantiate the service renes1 ans wait 
until it is completely instantiated

```
osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim
watch osm ns-list
```

Exit with ctrl+C

6. On RDSV-OSM, extract the deployment-ids of the KNFs

```
export NSTEXT=renes1
for i in access cpe; do 
  osm ns-list | grep $NSTEXT | awk '{split($0,a,"|");print a[3]}' | xargs osm vnf-list --ns | grep $i | awk '{split($0,a,"|");print a[2]}' | xargs osm vnf-show --literal | grep name | grep $i | awk '{split($0,a,":");print a[2]}'
done
```

7. On RDSV-K8S, configure two variables to hold the deployment-ids, copy-pasting the previous results

```
VACC1=helmchartrepo-accesschart-...
```

```
VCPE1=helmchartrepo-cpechart-...
```

8. Configure the KNFs:

```
export OSMNS=7b2950d8-f92b-4041-9a55-8d1837ad7b0a   #OSM namespace
./renes1.sh $VACC1 $VCPE1
```

9. On the VNX scenario, accesss the h11 terminal (root/xxxx) and  check connectivity

```
ifconfig eth1 # should have a 192.168.1.255.X/24 IP address
ping -c 5 8.8.8.8
firefox www.upm.es
```
