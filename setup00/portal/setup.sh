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
kubectl apply -f portal/00-namespace.yaml
echo "Create git secret"
kubectl delete -n dps-portal secret/git-token
kubectl create -n dps-portal secret generic git-token --from-literal username="token" --from-literal password="$GIT_TOKEN" --type=kubernetes.io/basic-auth
echo "Annotate secret"
kubectl annotate -n dps-portal secret git-token "tekton.dev/git-0"="https://github.ibm.com"
sleep 30
echo "Link secret to pipeline account"
# oc secrets -n dps-portal link pipeline git-token
kubectl patch -n dps-portal serviceaccount pipeline -p '{"secrets": [{"name": "git-token"}]}'

echo "Set RBAC"
kubectl apply -f portal/01-rbac.yaml

echo "Create  task"
kubectl apply -f portal/02-ibm-pak.yaml

#echo "Add permissions to default service account"
#oc adm policy add-scc-to-user anyuid -z default -n dps-portal

# gas - moved to deployer pipeline - not needed in next release
# echo "Create Minio S3 route for portal file upload"
# oc create route edge ibm-lh-lakehouse-minio-s3 --service ibm-lh-lakehouse-minio-svc --port 9000 -n cpd
# gas - end

# MOVED TO PIPELINE

# echo "Get CP4D information"
# export CPD_HOST=$(oc get route cpd -n cpd --template='{{ .spec.host }}')
# echo $CPD_HOST #DEBUG

# export CPD_ADMIN_PASSWORD=$(oc extract --namespace cpd configmap/vars-for-python --keys=cpadmin_password --to=-)

# export CPD_TOKEN=$(curl -s -X POST \
#   'https://'$CPD_HOST'/icp4d-api/v1/authorize' \
#   --header 'Content-Type: application/json' \
#   --data-raw '{"username": "cpadmin","password": "'$CPD_ADMIN_PASSWORD'"}' | jq --raw-output '.token')
# echo $CPD_TOKEN #DEBUG

# export CPD_LH_INST_ID=$(curl -s -X GET \
#   'https://'$CPD_HOST'/zen-data/v3/service_instances?display_name=lakehouse' \
#   --header 'Authorization: Bearer '$CPD_TOKEN | jq --raw-output '.service_instances[].id')
# echo $CPD_LH_INST_ID #DEBUG

# export S3_ENDPOINT=$(oc get route ibm-lh-lakehouse-minio-s3 -n cpd -o jsonpath="{.spec.host}")
# echo $S3_ENDPOINT #DEBUG

# echo "Get APIC Consumer information"
# export APIC_CONSUMER_HOST=$(oc get route -l app.kubernetes.io/name=consumer-api-endpoint -n integration -o jsonpath="{.items[].spec.host}")
# echo $APIC_CONSUMER_HOST #DEBUG

# APIC_SECRET=$(oc get  -n integration managementcluster api-management-mgmt -o jsonpath="{.status.consumerToolkitCredentialSecret}")
# APIC_SECRET_JSON=$(oc extract --namespace integration secret/$APIC_SECRET --keys=credential.json --to=-)
# echo $APIC_SECRET_JSON #DEBUG

# export APIC_CONSUMER_TOOLKIT_CLIENT_ID=$(echo $APIC_SECRET_JSON | jq -r '.id')
# echo $APIC_CONSUMER_TOOLKIT_CLIENT_ID #DEBUG

# export APIC_CONSUMER_TOOLKIT_CLIENT_SECRET=$(echo $APIC_SECRET_JSON | jq -r '.secret')
# echo $APIC_CONSUMER_TOOLKIT_CLIENT_SECRET #DEBUG

# export APIC_CONSUMER_AUTH_REALM=$(curl -s -k -X GET \
#   'https://'$APIC_CONSUMER_HOST'/consumer-api/consumer/identity-providers' \
#   --header 'Accept: */*' \
#   --header 'X-IBM-Consumer-Context: acme.marketplace' | jq '.results[] | select(.title == "openldap")' | jq --raw-output '.realm')
# echo $APIC_CONSUMER_AUTH_REALM #DEBUG


# echo "Get APIC Provider information"
# export APIC_PRODUCER_HOST=$(oc get route -l app.kubernetes.io/name=platform-api-endpoint -n integration -o jsonpath="{.items[].spec.host}")
# echo $APIC_PRODUCER_HOST #DEBUG

# APIC_SECRET=$(oc get  -n integration managementcluster api-management-mgmt -o jsonpath="{.status.toolkitCredentialSecret}")
# APIC_SECRET_JSON=$(oc extract --namespace integration secret/$APIC_SECRET --keys=credential.json --to=-)
# echo $APIC_SECRET_JSON #DEBUG

# export APIC_PROVIDER_TOOLKIT_CLIENT_ID=$(echo $APIC_SECRET_JSON | jq -r '.id')
# echo $APIC_PROVIDER_TOOLKIT_CLIENT_ID #DEBUG

# export APIC_PROVIDER_TOOLKIT_CLIENT_SECRET=$(echo $APIC_SECRET_JSON | jq -r '.secret')
# echo $APIC_PROVIDER_TOOLKIT_CLIENT_SECRET #DEBUG

# echo "Create portal secret"
# oc delete -n dps-portal secret/portal-secret
# oc create -n dps-portal secret generic portal-secret \
#   --from-literal NEXTAUTH_SECRET="mysecret" \
#   --from-literal NEXTAUTH_URL="" \
#   --from-literal CPD_HOST="https://$CPD_HOST" \
#   --from-literal CPD_ADMIN_USER="developer-1" \
#   --from-literal CPD_ADMIN_PASSWORD="passw0rd" \
#   --from-literal CPD_LH_INST_ID="$CPD_LH_INST_ID" \
#   --from-literal APIC_CONSUMER_HOST="https://$APIC_CONSUMER_HOST/consumer-api" \
#   --from-literal APIC_CONSUMER_TOOLKIT_CLIENT_ID="$APIC_CONSUMER_TOOLKIT_CLIENT_ID" \
#   --from-literal APIC_CONSUMER_TOOLKIT_CLIENT_SECRET="$APIC_CONSUMER_TOOLKIT_CLIENT_SECRET" \
#   --from-literal APIC_CONSUMER_AUTH_REALM="$APIC_CONSUMER_AUTH_REALM" \
#   --from-literal APIC_CONSUMER_ORG="consumer-org" \
#   --from-literal APIC_CONSUMER_APP="data_consumer_app" \
#   --from-literal APIC_PRODUCER_HOST="https://$APIC_PRODUCER_HOST/api" \
#   --from-literal APIC_PROVIDER_TOOLKIT_CLIENT_ID="$APIC_PROVIDER_TOOLKIT_CLIENT_ID" \
#   --from-literal APIC_PROVIDER_TOOLKIT_CLIENT_SECRET="$APIC_PROVIDER_TOOLKIT_CLIENT_SECRET" \
#   --from-literal APIC_PROVIDER_AUTH_REALM="provider/openldap" \
#   --from-literal APIC_ADMIN_USER="developer-1" \
#   --from-literal APIC_ADMIN_PASSWORD="passw0rd" \
#   --from-literal APIC_ORG="acme" \
#   --from-literal APIC_CATALOG="marketplace" \
#   --from-literal S3_ENDPOINT="https://$S3_ENDPOINT/" \
#   --from-literal S3_REGION="eu-de" \
#   --from-literal NODE_OPTIONS="--max-http-header-size=12800000" \
#   --from-literal SUPERSET_URL=""

echo "create pipeline"
kubectl delete -f portal/03-pipeline.yaml
kubectl create -f portal/03-pipeline.yaml

echo "start pipeline"
kubectl create -f portal/04-pipeline-run.yaml
