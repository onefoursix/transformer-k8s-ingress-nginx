#!/bin/sh

## Script to deploy an instance of Transformer with a Service and Ingress

## See the README at https://github.com/onefoursix/transformer-k8s-ingress-nginx/blob/main/README.md
## for prerequisites before running this script

## Make sure we have arg values for transformer-namespace and transformer-name
if [ $# != 5 ]; then
  echo "Error: wrong number of arguments"
  echo "Usage: $ ./deploy-transformer.sh <transformer-namespace> <transformer-name> <transformer-image> <port-number> <transformer-labels>"
  echo "Example: ./deploy-transformer.sh ns1 transformer1 streamsets/transformer:scala-2.12_4.2.0  19630 transformer,dev"
  exit -1
fi

export KUBE_NAMESPACE=$1
export TRANSFORMER_NAME=$2
export TRANSFORMER_IMAGE=$3
export TRANSFORMER_PORT=$4
export TRANSFORMER_LABELS=$5

./bin/deploy.sh
