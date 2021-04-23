@description('Name of the virtual network to use for cloud shell containers.')
param existingVNETName string

@description('Name of the subnet to use for storage account.')
param existingStorageSubnetName string

@description('Name of the subnet to use for cloud shell containers.')
param existingContainerSubnetName string

@description('Name of the storage account in subnet.')
param storageAccountName string

@description('Name of the fileshare in storage account.')
param fileShareName string = 'acsshare'

@description('Location for all resources.')
param location string = resourceGroup().location

var containerSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingContainerSubnetName)
var storageSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingStorageSubnetName)

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'None'
      virtualNetworkRules: [
        {
          id: containerSubnetRef
          action: 'Allow'
        }
        {
          id: storageSubnetRef
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Cool'
  }
}

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  parent: storageAccountName_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileServices@2019-06-01' = {
  parent: storageAccountName_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
}

resource storageAccountName_default_fileShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  parent: Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default
  name: fileShareName
  properties: {
    shareQuota: 6
  }
  dependsOn: [
    storageAccountName_resource
  ]
}