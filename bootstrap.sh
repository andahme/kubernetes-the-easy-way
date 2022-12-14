#!/usr/bin/env bash

set -e

if [ "$(whoami)" == "root" ]; then
  apt-get update
  if ! command -v pip3 &> /dev/null; then
    apt-get install --yes python3-pip
  fi
  if ! command -v ansible-playbook &> /dev/null; then
    pip3 install ansible
  fi
  exit 0
elif ! command -v ansible-playbook &> /dev/null; then
  echo "Cannot find ansible-playbook. Run this script as 'root' to install tools."
  echo
  echo "  sudo ./bootstrap.sh"
  echo
  exit 1
elif [ -z ${ANSIBLE_INVENTORY} ]; then
  echo "Please set the ansible inventory. eg."
  echo
  echo "  export ANSIBLE_INVENTORY=inventory/sg-test.yml"
  echo
  exit 1
fi


export ANSIBLE_INVENTORY=inventory/sg-test.yml

ansible-playbook --tags prepare \
  k8s-bootstrap.yml

ansible-playbook --tags gen-k8s,gen-tls \
  k8s-bootstrap.yml

ansible-playbook k8s-cluster.yml

ansible-playbook k8s-config.yml

kubectl apply \
  --filename resources/role-apiserver-to-kubelet.yaml \
  --filename resources/role-binding-apiserver-to-kubelet.yaml

kubectl apply \
  --filename resources/coredns.yaml


