#!/bin/bash

# Variables
resourceGroupName="PolicyTestRG"
policyDefinitionName="delete-test-policy-definition"

# Get subscriptionId
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)


# Get subscriptionId
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)
scope="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# Check if the policy definition exists
echo "Checking if [$policyDefinitionName] policy definition exists in [$subscriptionName] subscription..."
policyDefinitionId=$(az policy definition show --name $policyDefinitionName --query id --output tsv 2>/dev/null)
if [ -z $policyDefinitionId ]; then
	echo "No [$policyDefinitionName] policy exists in [$subscriptionName] subscription"
    exit
else
    echo "[$policyDefinitionName] policy definition found in [$subscriptionName] subscription"
fi

# Find all the assignments for the policy definition at the subscription scope
echo "Retrieving policy assignments for the [$policyDefinitionName] policy definition in the [$subscriptionName] subscription..."
policyAssignmentNames=$(az policy assignment list --scope $scope --query "[?policyDefinitionId=='$policyDefinitionId'].name" --output tsv)
if [ -z $policyAssignmentNames ]; then
    echo "No policy assignments exist for the [$policyDefinitionName] policy definition in the [$subscriptionName] subscription"
else
    echo "${#policyAssignmentNames[@]} policy assignments exist for the [$policyDefinitionName] policy definition in the [$subscriptionName] subscription"
    for policyAssignmentName in ${policyAssignmentNames[@]}
    do
        policyAssignmentName=$(echo $policyAssignmentName | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")
        echo "Deleting [$policyAssignmentName] policy assignment from the [$subscriptionName] subscription..."
        error=$(az policy assignment delete --name $policyAssignmentName --scope $scope 2>&1)
        if [[ $? == 0 ]]; then
            echo "[$policyAssignmentName] policy assignment successfully deleted from the [$subscriptionName] subscription"
        else
            echo "Failed to delete [$policyAssignmentName] policy assignment from the [$subscriptionName] subscription"
            echo -e "\033[38;5;1m${error}\033[m"
            exit
        fi
    done
fi