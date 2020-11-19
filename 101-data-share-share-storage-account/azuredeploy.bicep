param projectName string {
  metadata: {
    description: 'Specify a project name that is used to generate resource names.'
  }
}
param location string {
  allowed: [
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
  ]
  metadata: {
    description: 'Specify the location for the resources.'
  }
  default: resourceGroup().location
}
param invitationEmail string {
  metadata: {
    description: 'Specify an email address for receiving data share invitations.'
  }
}
param syncKind string {
  metadata: {
    description: 'Specify the kind of synchronization.'
  }
  default: 'ScheduleBased'
}
param syncInterval string {
  allowed: [
    'Day'
    'Hour'
  ]
  metadata: {
    description: 'Specify snapshot schedule recurrence.'
  }
  default: 'Day'
}
param syncTime string {
  metadata: {
    description: 'Specify snapshot schedule start time.'
  }
  default: utcNow('yyyy-MM-ddTHH:mm:ssZ')
}
param storageAccountSubscriptionID string {
  metadata: {
    description: 'Specify the subscription ID of the storage account. Because this template creates the storage account in the same resource group as the data sharing account, use the current subscription ID.'
  }
  default: subscription().subscriptionId
}
param storageAccountResourceGroupName string {
  metadata: {
    description: 'Specify the resource group of the storage account. Because this template creates the storage account in the same resource group as the data sharing account, use the resource group.'
  }
  default: resourceGroup().name
}

var storageAccountName_var = '${projectName}store'
var containerName = '${projectName}container'
var dataShareAccountName_var = '${projectName}shareaccount'
var dataShareName = '${projectName}share'
var roleAssignmentName = guid(uniqueString(storageAccountName_var, storageBlobDataReaderRoleDefinitionId, dataShareAccountName_var))
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
  name: '${dataShareAccountName_var}/${dataShareName}'
  properties: {
    shareKind: 'CopyBased'
  }
}

resource storageAccountName_Microsoft_Authorization_roleAssignmentName 'Microsoft.Storage/storageAccounts/providers/roleAssignments@2020-04-01-preview' = {
  name: '${storageAccountName_var}/Microsoft.Authorization/${roleAssignmentName}'
  properties: {
    roleDefinitionId: storageBlobDataReaderRoleDefinitionId
    principalId: reference(dataShareAccountName.id, '2019-11-01', 'Full').identity.principalId
  }
}

resource dataShareAccountName_dataShareName_containerName 'Microsoft.DataShare/accounts/shares/dataSets@2019-11-01' = {
  name: '${dataShareAccountName_var}/${dataShareName}/${containerName}'
  kind: 'Container'
  properties: {
    subscriptionId: storageAccountSubscriptionID
    resourceGroup: storageAccountResourceGroupName
    storageAccountName: storageAccountName_var
    containerName: containerName
  }
}

resource dataShareAccountName_dataShareName_inviteName 'Microsoft.DataShare/accounts/shares/invitations@2019-11-01' = {
  name: '${dataShareAccountName_var}/${dataShareName}/${inviteName}'
  properties: {
    targetEmail: invitationEmail
  }
}

resource dataShareAccountName_dataShareName_dataShareName_synchronizationSetting 'Microsoft.DataShare/accounts/shares/synchronizationSettings@2019-11-01' = {
  name: '${dataShareAccountName_var}/${dataShareName}/${dataShareName}_synchronizationSetting'
  kind: syncKind
  properties: {
    recurrenceInterval: syncInterval
    synchronizationTime: syncTime
  }
}