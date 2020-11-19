param existingVNETName string {
  metadata: {
    description: 'Name of the virtual network to use for cloud shell containers.'
  }
}
param existingStorageSubnetName string {
  metadata: {
    description: 'Name of the subnet to use for storage account.'
  }
}
param existingContainerSubnetName string {
  metadata: {
    description: 'Name of the subnet to use for cloud shell containers.'
  }
}
param storageAccountName string {
  metadata: {
    description: 'Name of the storage account in subnet.'
  }
}
param fileShareName string {
  metadata: {
    description: 'Name of the fileshare in storage account.'
  }
  default: 'acsshare'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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
  name: '${storageAccountName}/default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    deleteRetentionPolicy: {
      enabled: false
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileServices@2019-06-01' = {
  name: '${storageAccountName}/default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource storageAccountName_default_fileShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name: '${storageAccountName}/default/${fileShareName}'
  properties: {
    shareQuota: 6
  }
  dependsOn: [
    Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default
    storageAccountName_resource
  ]
}