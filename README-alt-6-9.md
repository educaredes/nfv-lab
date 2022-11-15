# Alternative steps for testing

After following 1-6 from [README.md](README.md) then:

1. On RDSV-OSM, extract the deployment-ids of the KNFs:

```
export NSTEXT=renes1
for i in access cpe; do 
  osm ns-list | grep $NSTEXT | awk '{split($0,a,"|");print a[3]}' | xargs osm vnf-list --ns | grep $i | awk '{split($0,a,"|");print a[2]}' | xargs osm vnf-show --literal | grep name | grep $i | awk '{split($0,a,":");print a[2]}'
done
```

2. On RDSV-K8S, configure two variables to hold the deployment-ids, copy-pasting the previous results:

```
VACC1=helmchartrepo-accesschart-...
```

```
VCPE1=helmchartrepo-cpechart-...
```

3. Configure the KNFs:

```
export OSMNS=7b2950d8-f92b-4041-9a55-8d1837ad7b0a   #OSM namespace
./k8s_renes1.sh $VACC1 $VCPE1
```

4. On the VNX scenario, accesss the h11 terminal (root/xxxx) and check connectivity:

```
ifconfig eth1 # should have a 192.168.1.255.X/24 IP address
ping -c 5 8.8.8.8
firefox www.upm.es
```