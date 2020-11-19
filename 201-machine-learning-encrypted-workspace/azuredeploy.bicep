param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning workspace.'
  }
}
param location string {
  allowed: [
    'eastus'
    'eastus2'
    'southcentralus'
    'southeastasia'
    'westcentralus'
    'westeurope'
    'westus2'
  ]
  metadata: {
    description: 'Specifies the location for all resources.'
  }
}
param sku string {
  allowed: [
    'basic'
    'enterprise'
  ]
  metadata: {
    description: 'Specifies the sku, also referred to as \'edition\' of the Azure Machine Learning workspace.'
  }
  default: 'enterprise'
}
param confidential_data bool {
  metadata: {
    description: 'Specifies that the Azure Machine Learning workspace holds highly confidential data.'
  }
  default: true
}
param encryption_status string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Specifies if the Azure Machine Learning workspace should be encrypted with the customer managed key.'
  }
  default: 'Enabled'
}
param cmk_keyvault_id string {
  metadata: {
    description: 'Specifies the customer managed keyvault Resource Manager ID.'
  }
}
param resource_cmk_uri string {
  metadata: {
    description: 'Specifies the customer managed keyvault key uri.'
  }
}

var storageAccountName_var = 'sa${uniqueString(resourceGroup().id)}'
var storageAccountType = 'Standard_LRS'
var applicationInsightsName_var = 'ai${uniqueString(resourceGroup().id)}'
var containerRegistryName_var = 'cr${uniqueString(resourceGroup().id)}'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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

resource applicationInsightsName 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName_var
  location: location
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

resource workspaceName_res 'Microsoft.MachineLearningServices/workspaces@2020-01-01' = {
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
    keyVault: cmk_keyvault_id
    applicationInsights: applicationInsightsName.id
    containerRegistry: containerRegistryName.id
    storageAccount: storageAccountName.id
    encryption: {
      status: encryption_status
      keyVaultProperties: {
        keyVaultArmId: cmk_keyvault_id
        keyIdentifier: resource_cmk_uri
      }
    }
    hbiWorkspace: confidential_data
  }
}