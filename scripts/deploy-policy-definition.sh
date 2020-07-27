#!/bin/bash

# Variables
location="WestEurope"

# ARM template and parameters files
template="../templates/azuredeploy.policy.definition.json"
parameters="../templates/azuredeploy.policy.definition.parameters.json"

# SubscriptionId of the current subscription
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)

# Deploy the ARM template
echo "Deploying ["$template"] ARM template in the [$subscriptionName] subscription..."

az deployment sub create \
    --location $location \
    --template-file $template \
    --parameters $parameters \
    --only-show-errors

if [[ $? == 0 ]]; then
    echo "["$template"] ARM template successfully provisioned in the [$subscriptionName] subscription"
    deploymentName=$(echo $template | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
else
    echo "Failed to provision the ["$template"] ARM template in the [$subscriptionName] subscription"
    exit -1
fi