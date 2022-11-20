## Provision Infrastructure

##### Create Bastion
```bash
aws cloudformation \
  create-stack \
  --stack-name sg-dev-bastion \
  --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/bastion.template \
  --parameters \
    ParameterKey=Group,ParameterValue=sg \
    ParameterKey=SubGroup,ParameterValue=dev \
    ParameterKey=UserName,ParameterValue=gutano \
    ParameterKey=KeyName,ParameterValue=adabook
```

##### Create a Master (11-13)
```bash
for INDEX in $(seq 11 13); do
  aws cloudformation \
    create-stack \
    --stack-name sg-dev-master-${INDEX} \
    --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/k8s/master.template \
    --parameters \
      ParameterKey=Group,ParameterValue=sg \
      ParameterKey=SubGroup,ParameterValue=dev \
      ParameterKey=MasterNumber,ParameterValue=${INDEX} \
      ParameterKey=UserName,ParameterValue=gutano \
      ParameterKey=KeyName,ParameterValue=adabook
done
```

##### Create a Worker (101-102)
```bash
for INDEX in $(seq 101 102); do
  aws cloudformation \
    create-stack \
    --stack-name sg-dev-worker-${INDEX} \
    --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/k8s/worker.template \
    --parameters \
      ParameterKey=Group,ParameterValue=sg \
      ParameterKey=SubGroup,ParameterValue=dev \
      ParameterKey=WorkerNumber,ParameterValue=${INDEX} \
      ParameterKey=UserName,ParameterValue=gutano \
      ParameterKey=KeyName,ParameterValue=adabook
done
```


## Generate Configuration

##### Install Tools
```bash
ansible-playbook \
  --inventory dev.inventory.yml \
  --tags prepare \
  k8s-bootstrap.yml
```

##### Generate Kubernetes Encryption Secret and TLS Certificates
```bash
ansible-playbook \
  --inventory dev.inventory.yml \
  --tags gen-k8s,gen-tls \
  k8s-bootstrap.yml
```

##### Encrypt Configuration Files
```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vaultpass
```
```bash
echo PASSWORD > ${ANSIBLE_VAULT_PASSWORD_FILE}
```
```bash
ansible-vault encrypt \
  group_vars/dev/k8s-encryption-secret \
  $(find lib -type f)
```


## Provision Hosts

#### Create Cluster
```bash
ansible-playbook \
  --inventory dev.inventory.yml \
  k8s-cluster.yml
```

#### Generate Client Configuration
```bash
ansible-playbook \
  --inventory dev.inventory.yml \
  k8s-config.yml
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


## Quick Teardown
```bash
aws cloudformation delete-stack --stack-name sg-dev-bastion

for INDEX in $(seq 11 13); do
  aws cloudformation delete-stack --stack-name sg-dev-master-${INDEX}
done

for INDEX in $(seq 101 102); do
  aws cloudformation delete-stack --stack-name sg-dev-worker-${INDEX}
done
```

