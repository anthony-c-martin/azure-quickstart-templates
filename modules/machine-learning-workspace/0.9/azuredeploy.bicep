param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning workspace.'
  }
  default: 'ml-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Specifies the location for all resources.'
  }
  default: resourceGroup().location
}
param storageAccountName string {
  metadata: {
    description: 'The name for the storage account to created and associated with the workspace.'
  }
  default: 'sa${uniqueString(resourceGroup().id)}'
}
param keyVaultName string {
  metadata: {
    description: 'The name for the key vault to created and associated with the workspace.'
  }
  default: 'kv-${uniqueString(resourceGroup().id)}'
}
param applicationInsightsName string {
  metadata: {
    description: 'The name for the application insights to created and associated with the workspace.'
  }
  default: 'ai-${uniqueString(resourceGroup().id)}'
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: false
    accessPolicies: []
  }
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource workspaceName_resource 'Microsoft.MachineLearningServices/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'systemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccountName_resource.id
    keyVault: keyVaultName_resource.id
    applicationInsights: applicationInsightsName_resource.id
  }
  dependsOn: [
    applicationInsightsName_resource
    keyVaultName_resource
    storageAccountName_resource
  ]
}

output workspaceName_output string = workspaceName
output storageAccountName_output string = storageAccountName
output keyVaultName_output string = keyVaultName
output applicationInsightsName_output string = applicationInsightsName
output location_output string = location