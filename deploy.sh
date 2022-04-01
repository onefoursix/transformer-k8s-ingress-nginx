#!/bin/sh

## Set these variables ###########

# Control Hub Org ID
SCH_ORG_ID=

# Control Hub Base URL (with no trailing slash)
# Typically https://na01.hub.streamsets.com
SCH_URL=

# Control Hub user CRED ID 
CRED_ID=

# Control Hub user CRED TOKEN 
CRED_TOKEN=

# The Kubernetes namespace to deploy Transformer in (must exist in advance)
KUBE_NAMESPACE=

## Set the URL for Transformer as it will be exposed through the Ingress
TRANSFORMER_EXTERNAL_URL=

## End of user-defined variables ###########



## Set the namespace 
kubectl config set-context --current --namespace="${KUBE_NAMESPACE}"

## Get an auth token for Transformer
TRANSFORMER_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG_ID}\", \"componentType\" : \"transformer\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG_ID}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-App-Component-Id:${CRED_ID}" --header "X-SS-App-Auth-Token:${CRED_TOKEN}" | jq '.[0].fullAuthToken')

## Store the token in a secret
kubectl create secret generic streamsets-transformer-creds \
    --from-literal=transformer_token_string="${TRANSFORMER_TOKEN}"

## Generate a UUID for transformer
transformer_id=$(docker run --rm andyneff/uuidgen uuidgen -t)
echo "${transformer_id}" > transformer.id

    
## Store connection properties in a configmap for transformer
kubectl create configmap streamsets-transformer-config \
    --from-literal=org="${SCH_ORG_ID}" \
    --from-literal=sch_url="${SCH_URL}" \
    --from-literal=transformer_id="${transformer_id}" \
    --from-literal=transformer_external_url="${TRANSFORMER_EXTERNAL_URL}"  

## Delete the transformer.id file  
rm transformer.id

## Create a service account to run Transformer
kubectl create serviceaccount streamsets-transformer --namespace="${KUBE_NAMESPACE}"

## Create a role for the service account
kubectl create role streamsets-transformer \
    --verb=get,list \
    --resource=secrets,configmaps \
    --namespace="${KUBE_NAMESPACE}"

## Bind the role to the service account
kubectl create rolebinding streamsets-transformer \
    --role=streamsets-transformer \
    --serviceaccount="${KUBE_NAMESPACE}":streamsets-transformer \
    --namespace="${KUBE_NAMESPACE}"

# Deploy Transformer
kubectl apply -f yaml/transformer.yaml

# Deploy Transformer Service
kubectl apply -f yaml/service.yaml

# Deploy Transformer Ingress
kubectl apply -f yaml/ingress.yaml




