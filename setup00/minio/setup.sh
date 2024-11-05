#!/bin/bash

kubestl_LOGIN=$(kubectl auth whoami -o json | jq -r .status.userInfo.username)
if [ -z "$kubestl_LOGIN" ] ; then
  echo "No OpenShift session available. Please login to your cluster or copy login command. Exiting..."
  echo "kubestl login --token=sha256~yourToken --server=https://yourClusterURL:6443"
  exit 1
  else
  echo "Logged as $kubestl_LOGIN"
fi


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
kubestl apply -f minio/00-namespace.yaml
echo "Create git secret"
kubestl create -n minio-webhook secret generic git-token --from-literal username="token" --from-literal password="$GIT_TOKEN" --type=kubernetes.io/basic-auth
echo "Annotate secret"
kubestl annotate -n minio-webhook secret git-token "tekton.dev/git-0"="https://github.ibm.com"
# need to wait till pipeline sa is correctly created for the namespace
sleep 30
echo "Link secret to pipeline account"
kubestl secrets -n minio-webhook link pipeline git-token

echo "Set RBAC"
kubestl apply -f minio/01-rbac.yaml

# export PRESTO_ENDPOINT=$(kubestl get -n cpd route ibm-lh-lakehouse-presto-01-presto-svc -o jsonpath='{.spec.host}')


# echo "Create minio-webhook-secret"
# kubestl create -n minio-webhook secret generic minio-webhook-secret \
#   --from-literal PRESTO_CATALOG="marketplace" \
#   --from-literal PRESTO_ENDPOINT="$PRESTO_ENDPOINT:443" \
#   --from-literal PRESTO_SCHEMA="acme_m" \
#   --from-literal PRESTO_SSL="true" \
#   --from-literal TRUSTSTORE="/certs/truststorebundle.jks" \
#   --from-literal TRUSTSTORE_PASSWORD="changeit" 


# echo "Extract truststorebundle.jks"
# kubestl extract --namespace cpd secret/ibm-lh-tls-secret --keys=truststorebundle.jks --to=.

# echo "Create  lh-cert secret"
# kubestl create -n minio-webhook secret generic lh-cert --from-file truststorebundle.jks

echo "Create  task"
kubestl apply -f minio/02-ibm-pak.yaml

echo "Create  pipeline"
kubestl apply -f minio/03-pipeline.yaml

echo "Start  pipeline"
kubestl create -f minio/04-pipeline-run.yaml


