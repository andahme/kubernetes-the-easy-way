## Set Inventory
```bash
ANSIBLE_INVENTORY=inventory/sg-test.yml
```

## Generate Configuration

##### Install Tools
```bash
ansible-playbook --tags prepare \
  k8s-bootstrap.yml
```

##### Generate Kubernetes Encryption Secret and TLS Certificates
```bash
ansible-playbook --tags gen-k8s,gen-tls \
  k8s-bootstrap.yml
```

## Provision Hosts

#### Create Cluster
```bash
ansible-playbook k8s-cluster.yml
```

#### Generate Client Configuration
```bash
ansible-playbook k8s-config.yml
```

#### Create Roles and Role Bindings
```bash
kubectl apply \
  --filename resources/role-apiserver-to-kubelet.yaml \
  --filename resources/role-binding-apiserver-to-kubelet.yaml
```

#### Create Deployments
```bash
kubectl apply \
  --filename resources/coredns.yaml
```
