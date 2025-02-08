#!/bin/bash

# Variables
INV_PATH_NAME="mycluster"
KUBESPRAY_RELEASE_VER="2.27"
ANSIBLE_VER="2.16.4"

#Add kubespray from GitHub
git clone https://github.com/kubernetes-sigs/kubespray.git
python3 -m venv venv
source venv/bin/activate
cp -rfp ./kubespray/inventory/sample ./kubespray/inventory/$INV_PATH_NAME

# Deploy infrastructure for k8s-cluster
terraform init
terraform apply

# Prepare env for install k8s-cluster
cd kubespray/
git checkout release-$KUBESPRAY_RELEASE_VER
pip install -U -r requirements.txt
pip install "ansible>= $ANSIBLE_VER"

# Install k8s-cluster
ansible-playbook -i inventory/$INV_PATH_NAME/inventory.ini cluster.yml