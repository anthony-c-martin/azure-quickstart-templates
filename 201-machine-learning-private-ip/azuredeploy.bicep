param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning service workspace.'
  }
  default: 'workspace${uniqueString(resourceGroup().id)}'
}
param location string {
  allowed: [
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
  ]
  metadata: {
    description: 'Specifies the location for all resources.'
  }
}
param vmSize string {
  metadata: {
    description: 'Specifies the VM size of the agents.'
  }
  default: 'Standard_D3_v2'
}
param agentCount int {
  metadata: {
    description: 'Specifies the agent count.'
  }
  default: 3
}

var storageAccountName = 'sa${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var keyVaultName = 'kv${uniqueString(resourceGroup().id)}'
var tenantId = subscription().tenantId
var applicationInsightsName = 'ai${uniqueString(resourceGroup().id)}'
var containerRegistryName = 'cr${uniqueString(resourceGroup().id)}'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = {
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

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2018-02-14' = {
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
  location: (((location == 'eastus2') || (location == 'westcentralus')) ? 'southcentralus' : location)
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource containerRegistryName_resource 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: containerRegistryName
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
    type: 'systemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    keyVault: keyVaultName_resource.id
    applicationInsights: applicationInsightsName_resource.id
    containerRegistry: containerRegistryName_resource.id
    storageAccount: storageAccountName_resource.id
  }
  dependsOn: [
    storageAccountName_resource
    keyVaultName_resource
    applicationInsightsName_resource
    containerRegistryName_resource
  ]
}

resource workspaceName_compute_with_ilb 'Microsoft.MachineLearningServices/workspaces/computes@2018-11-19' = {
  name: '${workspaceName}/compute-with-ilb'
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
  dependsOn: [
    workspaceName_resource
  ]
}