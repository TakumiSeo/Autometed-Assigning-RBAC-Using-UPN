@description('the location of the deployment')
param location string = resourceGroup().location

@description('UPN')
param upn string

// before runnnig, this user assigned identity should be created
// and need to have User Administorator (maybe less previledged roll works) at Entra tenat scope
@description('the user assignd identity id name')
var userAssignedIdentityIdName = '/subscriptions/${subscription().subscriptionId}/resourceGroups/rg-roleassignment-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mid-roleassign-v2'

@description('the user assignd identity object id')
var userAssignedIdentityId = ''

@description('The name of the deployment script')
var deploymentScriptName = 'configScript'

@description('thr storage account name that is consumed by the deployment script')
var storageAccountName = 'storage${uniqueString(resourceGroup().id)}'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}


resource umidRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
    principalId: userAssignedIdentityId
    principalType: 'ServicePrincipal'
  }
}


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityIdName}' : {}
    }
  }
  properties: {
    azCliVersion: '2.59.0'
    retentionInterval: 'PT1H'
    arguments: '${upn} ${resourceGroup().id}'
    scriptContent: '''
    #!/bin/bash
    set -e
    az role assignment create --assignee $1 --role "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1" --scope $2
    '''
  }
  dependsOn: [
    storageAccount
    umidRoleAssignment
  ]
}
