#!/bin/bash
echo "Looking for GIT_TOKEN"
if [ -z "$GIT_TOKEN" ] ; then
  echo "No GIT_TOKEN variable defined. Exiting..."
  echo "Make sure you correctly configured your git token running the following command:"
  echo "export GIT_TOKEN=your-git-token-here"
  exit 1
  else
  echo "GIT_TOKEN exist - continuing deployment"
fi

echo "Create namespace"
kubectl apply -f csv-downloader/00-namespace.yaml
echo "Create git secret"
kubectl create -n csv-downloader secret generic git-token --from-literal username="token" --from-literal password="$GIT_TOKEN" --type=kubernetes.io/basic-auth
echo "Annotate secret"
kubectl annotate -n csv-downloader secret git-token "tekton.dev/git-0"="https://github.ibm.com"
# need to wait till pipeline sa is correctly created for the namespace
sleep 30
echo "Link secret to pipeline account"
#oc secrets -n csv-downloader link pipeline git-token
kubectl patch -n csv-downloader serviceaccount pipeline -p '{"secrets": [{"name": "git-token"}]}'

echo "Set RBAC"
kubectl apply -f csv-downloader/01-rbac.yaml

# export PRESTO_ENDPOINT=$(kubectl get -n cpd route ibm-lh-lakehouse-presto-01-presto-svc -o jsonpath='{.spec.host}')


# echo "Create csv-downloader-secret"
# kubectl create -n csv-downloader secret generic csv-downloader-secret \
#   --from-literal PRESTO_CATALOG="marketplace" \
#   --from-literal PRESTO_ENDPOINT="$PRESTO_ENDPOINT:443" \
#   --from-literal PRESTO_SCHEMA="acme_m" \
#   --from-literal PRESTO_SSL="true" \
#   --from-literal TRUSTSTORE="/certs/truststorebundle.jks" \
#   --from-literal TRUSTSTORE_PASSWORD="changeit" 


# echo "Extract truststorebundle.jks"
# kubectl extract --namespace cpd secret/ibm-lh-tls-secret --keys=truststorebundle.jks --to=.

# echo "Create  lh-cert secret"
# kubectl create -n csv-downloader secret generic lh-cert --from-file truststorebundle.jks

echo "Create  task"
kubectl apply -f csv-downloader/02-ibm-pak.yaml

echo "Create  pipeline"
kubectl apply -f csv-downloader/03-pipeline.yaml

echo "Start  pipeline"
kubectl create -f csv-downloader/04-pipeline-run.yaml


