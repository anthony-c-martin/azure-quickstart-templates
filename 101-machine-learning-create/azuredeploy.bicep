@description('Specifies the name of the Azure Machine Learning workspace.')
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

@allowed([
  'basic'
  'enterprise'
])
@description('Specifies the sku, also referred as \'edition\' of the Azure Machine Learning workspace.')
param sku string = 'basic'

@allowed([
  'new'
  'existing'
])
param storageAccountNewOrExisting string = 'new'
param storageAccountName string = 'sa${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountType string = 'Standard_LRS'
param storageAccountResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
])
@description('Determines whether or not a key vault should be provisioned.')
param keyVaultNewOrExisting string = 'new'
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'
param keyVaultResourceGroupName string = resourceGroup().name

@allowed([
  'new'
  'existing'
])
param applicationInsightsNewOrExisting string = 'new'
param applicationInsightsName string = 'ai${uniqueString(resourceGroup().id)}'
param applicationInsightsResourceGroupName string = resourceGroup().name

@description('The container registry resource id if you want to create a link to the workspace.')
param containerRegistry string = ''

@description('Azure Databrick workspace resource id to be linked to the workspace')
param adbWorkspace string = ''

@allowed([
  'false'
  'true'
])
@description('Specifies that the Azure Machine Learning workspace holds highly confidential data.')
param confidential_data string = 'false'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies if the Azure Machine Learning workspace should be encrypted with customer managed key.')
param encryption_status string = 'Disabled'

@description('Specifies the customer managed keyVault arm id.')
param cmk_keyvault string = ''

@description('Specifies if the customer managed keyvault key uri.')
param resource_cmk_uri string = ''

var tenantId = subscription().tenantId
var storageAccount = resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccountName)
var keyVault = resourceId(keyVaultResourceGroupName, 'Microsoft.KeyVault/vaults', keyVaultName)
var applicationInsights = resourceId(applicationInsightsResourceGroupName, 'Microsoft.Insights/components', applicationInsightsName)

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = if (storageAccountNewOrExisting == 'new') {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
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

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2019-09-01' = if (keyVaultNewOrExisting == 'new') {
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

resource applicationInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = if (applicationInsightsNewOrExisting == 'new') {
  name: applicationInsightsName
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
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
  sku: {
    tier: sku
    name: sku
  }
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccount
    keyVault: keyVault
    applicationInsights: applicationInsights
    containerRegistry: (empty(containerRegistry) ? json('null') : containerRegistry)
    adbWorkspace: (empty(adbWorkspace) ? json('null') : adbWorkspace)
    encryption: {
      status: encryption_status
      keyVaultProperties: {
        keyVaultArmId: cmk_keyvault
        keyIdentifier: resource_cmk_uri
      }
    }
    hbiWorkspace: confidential_data
  }
  dependsOn: [
    storageAccount
    keyVault
    applicationInsights
  ]
}