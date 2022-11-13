#!/bin/bash

echo "Creating external interfaces"
sudo ovs-vsctl --if-exists del-br AccessNet1
sudo ovs-vsctl --if-exists del-br AccessNet2
sudo ovs-vsctl --if-exists  del-br ExtNet1
sudo ovs-vsctl --if-exists  del-br ExtNet2
sudo ovs-vsctl --if-exists  del-br MplsWan
sudo ovs-vsctl add-br AccessNet1
sudo ovs-vsctl add-br AccessNet2
sudo ovs-vsctl add-br ExtNet1
sudo ovs-vsctl add-br ExtNet2
sudo ovs-vsctl add-br MplsWan
