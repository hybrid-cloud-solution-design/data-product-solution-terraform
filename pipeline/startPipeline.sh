#!/bin/bash

echo "Entitlement key: ${IBM_ENTITLEMENT_KEY}"
echo "Replacing"
ls -la
sed -i 's|value: "${ibm-entitlement-key}"|value: \"'${IBM_ENTITLEMENT_KEY}'\"|g;' pipeline\dps-deployer-pipeline-run.yaml
cat pipeline\dps-deployer-pipeline-run.yaml
kubectl create -f pipeline\dps-deployer-pipeline-run.yaml