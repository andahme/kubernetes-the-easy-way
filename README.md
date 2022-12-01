## Context
export AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export GROUP=sg
export SUBGROUP=test

## Provision Infrastructure

#### Apply Kubernetes Extension
```bash
aws cloudformation \
  create-stack \
  --stack-name ${GROUP}-${SUBGROUP}-k8s \
  --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/k8s/k8s.template \
  --notification-arns arn:aws:sns:us-east-1:${AWS_ACCOUNT}:${GROUP}-lifecycle \
  --parameters \
    ParameterKey=Group,ParameterValue=${GROUP} \
    ParameterKey=SubGroup,ParameterValue=${SUBGROUP}
```

##### Create a Master (11-13)
```bash
for INDEX in $(seq 11 13); do
  aws cloudformation \
    create-stack \
    --stack-name ${GROUP}-${SUBGROUP}-k8s-master-${INDEX} \
    --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/k8s/master.template \
    --notification-arns arn:aws:sns:us-east-1:${AWS_ACCOUNT}:${GROUP}-lifecycle \
    --parameters \
      ParameterKey=Group,ParameterValue=${GROUP} \
      ParameterKey=SubGroup,ParameterValue=${SUBGROUP} \
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
    --stack-name ${GROUP}-${SUBGROUP}-k8s-worker-${INDEX} \
    --template-url https://s3.amazonaws.com/aws.andah.me/cloudformation/v0.0.4-SNAPSHOT/group/subgroup/k8s/worker.template \
    --notification-arns arn:aws:sns:us-east-1:${AWS_ACCOUNT}:${GROUP}-lifecycle \
    --parameters \
      ParameterKey=Group,ParameterValue=${GROUP} \
      ParameterKey=SubGroup,ParameterValue=${SUBGROUP} \
      ParameterKey=WorkerNumber,ParameterValue=${INDEX} \
      ParameterKey=UserName,ParameterValue=gutano \
      ParameterKey=KeyName,ParameterValue=adabook
done
```


## Context
```bash
export ANSIBLE_INVENTORY=inventory/test.yml
```

## Generate Configuration

##### Install Tools
```bash
ansible-playbook --tags prepare k8s-bootstrap.yml
```

##### Generate Kubernetes Encryption Secret and TLS Certificates
```bash
ansible-playbook --tags gen-k8s,gen-tls k8s-bootstrap.yml
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
  group_vars/${SUBGROUP}/k8s-encryption-secret \
  $(find lib -type f)
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
kubectl apply --filename resources/coredns.yaml
```


## Quick Teardown
```bash
aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s-worker-102
aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s-worker-101

aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s-master-13
aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s-master-12
aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s-master-11

aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-k8s

aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-bastion

aws cloudformation delete-stack --stack-name ${GROUP}-${SUBGROUP}-subnet
```

