#!/bin/bash

# Variables
storageAccountName="babofufos"
resourceGroupName="PolicyTestRG"

# Get subscriptionId
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)
scope="/subscriptions/$subscriptionId"

# Check if the storage account exists
echo "Checking if [$storageAccountName] storage account exists in [$subscriptionName] subscription..."
storageAccountId=$(az storage account show \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --query id \
    --output tsv 2>/dev/null)

if [ -z $storageAccountId ]; then
	echo "No [$storageAccountName] policy exists in [$subscriptionName] subscription"
    exit
else
    echo "[$storageAccountName] storage account found in [$subscriptionName] subscription"
fi

# Delete the storage account
echo "Deleting [$storageAccountName] storage account from the [$subscriptionName] subscription..."
error=$(az storage account delete --ids $storageAccountId --yes 2>&1)
if [[ $? == 0 ]]; then
    echo "[$storageAccountName] storage account successfully deleted from the [$subscriptionName] subscription"
else
    echo "Failed to delete [$storageAccountName] storage account from the [$subscriptionName] subscription"
    echo -e "\033[38;5;1m${error}\033[m"
fi