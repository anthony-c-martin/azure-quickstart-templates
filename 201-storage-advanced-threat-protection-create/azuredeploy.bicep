@description('The name must be unique across all existing storage account names in Azure. It must be 3 to 24 characters long, and can contain only lowercase letters and numbers.')
param storageAccountName string = 'atpstorage${uniqueString(resourceGroup().id)}'

@description('Storage account location, default is same as resource group location.')
param location string = resourceGroup().location

@allowed([
  'StorageV2'
  'Storage'
])
@description('Storage account type, for more info see \'https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview\'.')
param storageAccountKind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
@description('Storage account replication, for more info see \'https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy\'.')
param storageAccountReplication string = 'Standard_LRS'

@description('Enable or disable Advanced Threat Protection.')
param advancedThreatProtectionEnabled bool = true

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountReplication
  }
  kind: storageAccountKind
  properties: {}
}

resource storageAccountName_Microsoft_Security_current 'Microsoft.Storage/storageAccounts/providers/advancedThreatProtectionSettings@2019-01-01' = if (advancedThreatProtectionEnabled) {
  name: '${storageAccountName}/Microsoft.Security/current'
  properties: {
    isEnabled: true
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

output storageAccountName string = storageAccountName