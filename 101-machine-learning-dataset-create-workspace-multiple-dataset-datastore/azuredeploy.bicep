@description('Specifies name of workspace to create in Azure Machine Learning workspace.')
param workspaceName string

@allowed([
  'australiaeast'
  'brazilsouth'
  'canadacentral'
  'centralus'
  'eastasia'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'koreacentral'
  'northcentralus'
  'northeurope'
  'southeastasia'
  'southcentralus'
  'uksouth'
  'westcentralus'
  'westus'
  'westus2'
  'westeurope'
])
@description('Specifies the location for all resources.')
param location string

@description('Specifies the number of datastores to be created.')
param datastoreCount int = 2

@description('Specifies the number of datasets to be created.')
param datasetCount int = 2

@description('The name for the storage account to created and associated with the workspace.')
param storageAccountName string = 'sa${uniqueString(resourceGroup().id)}'

@description('The container name.')
param containerName string = 'container${uniqueString(resourceGroup().id)}'

@description('The name for the key vault to created and associated with the workspace.')
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'

@description('Specifies the tenant ID of the subscription. Get using Get-AzureRmSubscription cmdlet or Get Subscription API.')
param tenantId string = subscription().tenantId

@description('The name for the application insights to created and associated with the workspace.')
param applicationInsightsName string = 'ai${uniqueString(resourceGroup().id)}'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName}/default/${containerName}'
  dependsOn: [
    storageAccountName_resource
  ]
}

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: applicationInsightsName
  location: ((location == 'westcentralus') ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource workspaceName_resource 'Microsoft.MachineLearningServices/workspaces@2020-03-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccountName_resource.id
    keyVault: keyVaultName_resource.id
    applicationInsights: applicationInsightsName_resource.id
  }
}

resource workspaceName_datastore 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = [for i in range(0, int(datastoreCount)): {
  name: '${workspaceName}/datastore${i}'
  location: location
  properties: {
    dataStoreType: 'blob'
    AccountName: storageAccountName
    ContainerName: containerName
    AccountKey: listKeys(storageAccountName_resource.id, '2019-04-01').keys[0].value
  }
  dependsOn: [
    workspaceName_resource
    storageAccountName_resource
  ]
}]

resource workspaceName_dataset 'Microsoft.MachineLearningServices/workspaces/datasets@2020-05-01-preview' = [for i in range(0, int(datasetCount)): {
  name: '${workspaceName}/dataset${i}'
  location: location
  properties: {
    datasetType: 'file'
    Parameters: {
      Path: {
        DataPath: {
          RelativePath: '/'
          DatastoreName: 'workspaceblobstore'
        }
      }
    }
    Registration: {
      Description: 'Multiple datasets'
    }
  }
  dependsOn: [
    workspaceName_resource
  ]
}]