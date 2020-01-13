## Provision Infrastructure

##### Create Bastion
```bash
aws cloudformation \
  create-stack \
  --stack-name am-dev-bastion \
  --template-url https://s3.amazonaws.com/aws.andah.me/testing/group/subgroup/bastion.template \
  --parameters \
    ParameterKey=Group,ParameterValue=am \
    ParameterKey=SubGroup,ParameterValue=dev \
    ParameterKey=UserName,ParameterValue=gutano \
    ParameterKey=KeyName,ParameterValue=adabook
```

##### Create a Master (11)
```bash
aws cloudformation \
  create-stack \
  --stack-name am-dev-master-11 \
  --template-url https://s3.amazonaws.com/aws.andah.me/testing/group/subgroup/k8s/master.template \
  --parameters \
    ParameterKey=Group,ParameterValue=am \
    ParameterKey=SubGroup,ParameterValue=dev \
    ParameterKey=MasterNumber,ParameterValue=11 \
    ParameterKey=UserName,ParameterValue=gutano \
    ParameterKey=KeyName,ParameterValue=adabook
```

##### Create a Worker (101)
```bash
aws cloudformation \
  create-stack \
  --stack-name am-dev-worker-101 \
  --template-url https://s3.amazonaws.com/aws.andah.me/testing/group/subgroup/k8s/worker.template \
  --parameters \
    ParameterKey=Group,ParameterValue=am \
    ParameterKey=SubGroup,ParameterValue=dev \
    ParameterKey=WorkerNumber,ParameterValue=101 \
    ParameterKey=UserName,ParameterValue=gutano \
    ParameterKey=KeyName,ParameterValue=adabook
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
ANSIBLE_VAULT_PASSWORD_FILE=~/.vaultpass
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


