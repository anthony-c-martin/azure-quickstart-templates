param vaultName string {
  metadata: {
    description: 'Name of the Vault'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var omsWorkspaceName = '${uniqueString(resourceGroup().id)}ws'
var storageAccountName = '${uniqueString(resourceGroup().id)}storage'
var storageAccountType = 'Standard_LRS'

resource vaultName_resource 'Microsoft.RecoveryServices/vaults@2018-01-10' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource omsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsWorkspaceName
  location: 'East US'
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource vaultName_microsoft_insights_omsWorkspaceName 'Microsoft.RecoveryServices/vaults/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${vaultName}/microsoft.insights/${omsWorkspaceName}'
  properties: {
    name: omsWorkspaceName
    storageAccountId: storageAccountName_resource.id
    workspaceId: omsWorkspaceName_resource.id
    logs: [
      {
        category: 'AzureBackupReport'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: []
  }
  dependsOn: [
    vaultName_resource
    storageAccountName_resource
    omsWorkspaceName_resource
  ]
}