#!/bin/bash

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [ -z ${PLUGIN_KIND} ]; then
  PLUGIN_KIND="deployment"
fi

if [ ! -n ${PLUGIN_NAME} ]; then
  echo "container name must be configured!!!"
  exit 1
fi

if [ -z ${PLUGIN_KUBERNETES_CLUSTER} ]; then
  KUBERNETES_CLUSTER="default"
fi

if [ ! -z ${PLUGIN_KUBERNETES_TOKEN} ]; then
  KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${PLUGIN_KUBERNETES_CERT} ]; then
  KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT}
fi

if [ -z ${PLUGIN_TAG} ]; then
  PLUGIN_TAG="latest"
fi

echo ${KUBERNETES_CLUSTER}

sleep 30000

kubectl config set-credentials ${KUBERNETES_CLUSTER} --token=${KUBERNETES_TOKEN}
if [ ! -z ${KUBERNETES_CERT} ]; then
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster ${KUBERNETES_CLUSTER} --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster ${KUBERNETES_CLUSTER} --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context ${KUBERNETES_CLUSTER} --cluster=${KUBERNETES_CLUSTER} --user=${KUBERNETES_CLUSTER}
kubectl config use-context ${KUBERNETES_CLUSTER}

cat /root/.kube/config

echo "configurate over!!!"

# kubectl version
IFS=',' read -r -a KINDS <<< "${PLUGIN_KIND}"
IFS=',' read -r -a NAMES <<< "${PLUGIN_NAME}"

for KIND in ${KINDS[@]}; do
  echo Deploying to $KUBERNETES_SERVER
  for NAME in ${NAMES[@]}; do
    echo "kubectl -n ${PLUGIN_NAMESPACE} set image ${KIND}/${NAME} ${NAME}=${PLUGIN_REPO}:${PLUGIN_TAG} --record"
    kubectl -n ${PLUGIN_NAMESPACE} set image ${KIND}/${NAME} ${NAME}=${PLUGIN_REPO}:${PLUGIN_TAG} --record
  done
done
