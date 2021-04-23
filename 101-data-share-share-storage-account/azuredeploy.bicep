@description('Specify a project name that is used to generate resource names.')
param projectName string

@allowed([
  'eastus'
  'eastus2'
  'southeastasia'
  'westcentralus'
  'westeurope'
  'westus2'
  'austriliaeast'
  'northeurope'
  'uksouth'
  'usgovvirginia'
  'usgovarizona'
])
@description('Specify the location for the resources.')
param location string = resourceGroup().location

@description('Specify an email address for receiving data share invitations.')
param invitationEmail string

@description('Specify the kind of synchronization.')
param syncKind string = 'ScheduleBased'

@allowed([
  'Day'
  'Hour'
])
@description('Specify snapshot schedule recurrence.')
param syncInterval string = 'Day'

@description('Specify snapshot schedule start time.')
param syncTime string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

@description('Specify the subscription ID of the storage account. Because this template creates the storage account in the same resource group as the data sharing account, use the current subscription ID.')
param storageAccountSubscriptionID string = subscription().subscriptionId

@description('Specify the resource group of the storage account. Because this template creates the storage account in the same resource group as the data sharing account, use the resource group.')
param storageAccountResourceGroupName string = resourceGroup().name

var storageAccountName_var = '${projectName}store'
var containerName = '${projectName}container'
var dataShareAccountName_var = '${projectName}shareaccount'
var dataShareName = '${projectName}share'
var roleAssignmentName_var = guid(uniqueString(storageAccountName_var, storageBlobDataReaderRoleDefinitionId, dataShareAccountName_var))
var inviteName = '${dataShareName}invite'
var storageBlobDataReaderRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName_var}/default/${containerName}'
  dependsOn: [
    storageAccountName
  ]
}

resource dataShareAccountName 'Microsoft.DataShare/accounts@2019-11-01' = {
  name: dataShareAccountName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource dataShareAccountName_dataShareName 'Microsoft.DataShare/accounts/shares@2019-11-01' = {
  parent: dataShareAccountName
  name: '${dataShareName}'
  properties: {
    shareKind: 'CopyBased'
  }
}

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName_var
  properties: {
    roleDefinitionId: storageBlobDataReaderRoleDefinitionId
    principalId: reference(dataShareAccountName.id, '2019-11-01', 'Full').identity.principalId
  }
  scope: storageAccountName
}

resource dataShareAccountName_dataShareName_containerName 'Microsoft.DataShare/accounts/shares/dataSets@2019-11-01' = {
  parent: dataShareAccountName_dataShareName
  name: containerName
  kind: 'Container'
  properties: {
    subscriptionId: storageAccountSubscriptionID
    resourceGroup: storageAccountResourceGroupName
    storageAccountName: storageAccountName_var
    containerName: containerName
  }
  dependsOn: [
    dataShareAccountName
    extensionResourceId(storageAccountName.id, 'Microsoft.Authorization/roleAssignments', roleAssignmentName_var)
  ]
}

resource dataShareAccountName_dataShareName_inviteName 'Microsoft.DataShare/accounts/shares/invitations@2019-11-01' = {
  parent: dataShareAccountName_dataShareName
  name: inviteName
  properties: {
    targetEmail: invitationEmail
  }
  dependsOn: [
    dataShareAccountName
    extensionResourceId(storageAccountName.id, 'Microsoft.Authorization/roleAssignments', roleAssignmentName_var)
  ]
}

resource dataShareAccountName_dataShareName_dataShareName_synchronizationSetting 'Microsoft.DataShare/accounts/shares/synchronizationSettings@2019-11-01' = {
  parent: dataShareAccountName_dataShareName
  name: '${dataShareName}_synchronizationSetting'
  kind: syncKind
  properties: {
    recurrenceInterval: syncInterval
    synchronizationTime: syncTime
  }
  dependsOn: [
    dataShareAccountName
    extensionResourceId(storageAccountName.id, 'Microsoft.Authorization/roleAssignments', roleAssignmentName_var)
  ]
}