#!/bin/sh

## Get configuration properties
source conf/conf.sh

# Hardcoded names for Transformer ServiceAccount, Role, and RoleBinging
TRANSFORMER_SERVICE_ACCOUNT_NAME="streamsets-transformer-sa"
TRANSFORMER_ROLE_NAME="streamsets-transformer-role"
TRANSFORMER_ROLE_BINDING_NAME="streamsets-transformer-rb"

# Transformer URL
TRANSFORMER_URL="http://${LOAD_BALANCER_HOST_NAME}/${TRANSFORMER_NAME}" 

echo "Deploying ${TRANSFORMER_NAME} in namespace ${KUBE_NAMESPACE}..."

# Confirm the namespace exists
if kubectl get namespaces | grep  "${KUBE_NAMESPACE} " | grep -q Active ; then
  echo "Using existing namespace ${KUBE_NAMESPACE} "
else
  echo "Error: Namespace ${KUBE_NAMESPACE} does not exist"
  echo "Create the namespace first and then rerun the script"
  exit -1
fi


## Set the namespace 
kubectl config set-context --current --namespace="${KUBE_NAMESPACE}"

## Get an auth token for Transformer
TRANSFORMER_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG_ID}\", \"componentType\" : \"transformer\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG_ID}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-App-Component-Id:${CRED_ID}" --header "X-SS-App-Auth-Token:${CRED_TOKEN}" | jq '.[0].fullAuthToken')

## Store the token in a secret
kubectl create secret generic "${TRANSFORMER_NAME}-creds" \
  --from-literal=transformer_token_string="${TRANSFORMER_TOKEN}"

## Generate a UUID for transformer
TRANSFORMER_ID=$(uuidgen)
echo "${TRANSFORMER_ID}" > transformer.id

# Create the Transformer Service Account if it does not exist
echo "Looking for existing Service Accounts..."
if kubectl get serviceaccounts | grep "${TRANSFORMER_SERVICE_ACCOUNT_NAME} "; then
  echo "Using existing Service Account ${TRANSFORMER_SERVICE_ACCOUNT_NAME}"
else
  echo "Creating Service Account ${TRANSFORMER_SERVICE_ACCOUNT_NAME}"
  kubectl create serviceaccount "${TRANSFORMER_SERVICE_ACCOUNT_NAME}"  --namespace="${KUBE_NAMESPACE}"
fi

# Create the Transformer Role if it does not exist
echo "Looking for existing Roles..."
if kubectl get roles | grep "${TRANSFORMER_ROLE_NAME} "; then
  echo "Using existing Role ${TRANSFORMER_ROLE_NAME}"
else
  echo "Creating Role ${TRANSFORMER_ROLE_NAME}"
  kubectl create role "${TRANSFORMER_ROLE_NAME}" \
    --verb=get,list \
    --resource=secrets,configmaps \
    --namespace="${KUBE_NAMESPACE}"
fi

# Create the Transformer RoleBinding if it does not exist
echo "Looking for existing RolesBindings..."
if kubectl get rolebindings | grep "${TRANSFORMER_ROLE_BINDING_NAME} "; then
  echo "Using existing Role Binding ${TRANSFORMER_ROLE_BINDING_NAME}"
else
  echo "Creating Role Binding ${TRANSFORMER_ROLE_BINDING_NAME}"
  kubectl create rolebinding "${TRANSFORMER_ROLE_BINDING_NAME}"  \
    --role="${TRANSFORMER_ROLE_NAME}" \
    --serviceaccount="${KUBE_NAMESPACE}":"${TRANSFORMER_SERVICE_ACCOUNT_NAME}" \
    --namespace="${KUBE_NAMESPACE}"
fi
    
## Store connection properties in a configmap for transformer
kubectl create configmap "${TRANSFORMER_NAME}-config" \
    --from-literal=org="${SCH_ORG_ID}" \
    --from-literal=sch_url="${SCH_URL}" \
    --from-literal=transformer_id="${TRANSFORMER_ID}" \
    --from-literal=transformer_external_url="${TRANSFORMER_URL}"  

## Delete the transformer.id file  
rm transformer.id

# Deploy Transformer
envsubst < yaml/transformer.yaml | kubectl apply -f -

# Deploy Transformer Service
envsubst < yaml/service.yaml | kubectl apply -f -

# Deploy Transformer Ingress
envsubst < yaml/ingress.yaml | kubectl apply -f -

echo "Done"
exit 0


