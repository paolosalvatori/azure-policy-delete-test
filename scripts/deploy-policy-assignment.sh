#!/bin/bash

# Variables
resourceGroupName="PolicyTestRG"
location="WestEurope"
policyAssignmentName="delete-test-policy-assignment"
policyDefinitionName="delete-test-policy-definition"

# ARM template and parameters files
template="../templates/azuredeploy.policy.assignment.json"
parameters="../templates/azuredeploy.policy.assignment.parameters.json"

# SubscriptionId of the current subscription
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)
policyScope="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# Check if the policy definition exists
echo "Checking if [$policyDefinitionName] policy definition exists in [$subscriptionName] subscription..."
policyDefinitionId=$(az policy definition show --name $policyDefinitionName --query id --output tsv 2>/dev/null)

if [ -z $policyDefinitionId ]; then
    echo "No [$policyDefinitionName] policy exists in [$subscriptionName] subscription"
    exit
else
    echo "[$policyDefinitionName] policy definition found in [$subscriptionName] subscription"
fi

# Deploy the ARM template
echo "Deploying ["$template"] ARM template in the [$subscriptionName] subscription..."

az deployment group create \
    --resource-group $resourceGroupName \
    --template-file $template \
    --parameters $parameters \
    --parameters policyDefinitionName=$policyDefinitionName \
                 policyAssignmentName=$policyAssignmentName \
                 policyScope=$policyScope \
    --only-show-errors

if [[ $? == 0 ]]; then
    echo "["$template"] ARM template successfully provisioned in the [$subscriptionName] subscription"
    deploymentName=$(echo $template | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
else
    echo "Failed to provision the ["$template"] ARM template in the [$subscriptionName] subscription"
    exit -1
fi

# Retrieve the principalId of the system-assigned managed identity of the policy assignment
echo "Retrieving the principalId of the system-assigned managed identity of the [$policyAssignmentName] policy assignment..."
principalId=$(az policy assignment show \
    --name $policyAssignmentName \
    --scope $policyScope \
    --query identity.principalId \
    --output tsv)

if [[ -n $principalId ]]; then
    echo "[$principalId] principal id of the system-assigned managed identity of the [$policyAssignmentName] policy assignment successfully retrieved"
else
    echo "Failed to retrieve the principal id of the system-assigned managed identity of the [$policyAssignmentName]"
    exit
fi

# Retrieve the roleDefinitionIds from the policy definition
echo "Retrieving role definition ids from the [$policyDefinitionName] policy definition..."
roleDefinitionIds=$(az policy definition show \
    --name $policyDefinitionName \
    --subscription $subscriptionId \
    --query policyRule.then.details.roleDefinitionIds \
    --output tsv)

if [[ -z $roleDefinitionIds ]]; then
    echo "No role definition id was retrieved from the [$policyDefinitionName] policy definition"
fi

# Assign role to the system-assigned managed identity of the policy assignment
for roleDefinitionId in ${roleDefinitionIds[@]}; do
    echo "Assigning [$roleDefinitionId] role to the [$principalId] system-assigned managed identity of the [$policyAssignmentName] policy assignment on [$policyScope] scope..."
    az role assignment create --assignee "$principalId" --role "$roleDefinitionId" --scope "$policyScope" --only-show-errors

    if [[ $? == 0 ]]; then
        echo "[$roleDefinitionId] role successfully assigned to the [$principalId] system-assigned managed identity of the [$policyAssignmentName] policy assignment on [$policyScope] scope"
    else
        echo "Failed to assign the [$roleDefinitionId] role to the [$principalId] system-assigned managed identity of the [$policyAssignmentName] policy assignment on [$policyScope] scope"
    fi
done