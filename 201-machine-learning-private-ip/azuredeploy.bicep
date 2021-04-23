@description('Specifies the name of the Azure Machine Learning service workspace.')
param workspaceName string = 'workspace${uniqueString(resourceGroup().id)}'

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

@description('Specifies the VM size of the agents.')
param vmSize string = 'Standard_D3_v2'

@description('Specifies the agent count.')
param agentCount int = 3

var storageAccountName_var = 'sa${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var keyVaultName_var = 'kv${uniqueString(resourceGroup().id)}'
var tenantId = subscription().tenantId
var applicationInsightsName_var = 'ai${uniqueString(resourceGroup().id)}'
var containerRegistryName_var = 'cr${uniqueString(resourceGroup().id)}'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName_var
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

resource keyVaultName 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName_var
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

resource applicationInsightsName 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: applicationInsightsName_var
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource containerRegistryName 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: containerRegistryName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource workspaceName_resource 'Microsoft.MachineLearningServices/workspaces@2019-11-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    keyVault: keyVaultName.id
    applicationInsights: applicationInsightsName.id
    containerRegistry: containerRegistryName.id
    storageAccount: storageAccountName.id
  }
}

resource workspaceName_compute_with_ilb 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  parent: workspaceName_resource
  name: 'compute-with-ilb'
  location: location
  properties: {
    computeType: 'AKS'
    computeLocation: location
    properties: {
      agentVMSize: vmSize
      agentCount: agentCount
      loadBalancerType: 'InternalLoadBalancer'
    }
  }
}