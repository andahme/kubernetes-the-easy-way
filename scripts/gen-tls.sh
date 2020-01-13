#!/usr/bin/env bash


CA_KEY=$3/ca-key.pem
CA_CERT=$3/ca.pem


CFSSL_JSON='''{
  "CN": "CERT_CN",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Minneapolis",
      "O": "CERT_O",
      "OU": "Kubernetes The Hard Way",
      "ST": "Minnesota"
    }
  ]
}'''

echo ${CFSSL_JSON} \
  | sed \
      -e s/CERT_CN/$1/g \
      -e s/CERT_O/$2/g \
  | cfssl gencert \
      -ca=${CA_CERT} \
      -ca-key=${CA_KEY} \
      -profile=kubernetes \
      - \
  | cfssljson -bare \
      $3/$4

