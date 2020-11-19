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

var omsWorkspaceName_var = '${uniqueString(resourceGroup().id)}ws'
var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'
var storageAccountType = 'Standard_LRS'

resource vaultName_res 'Microsoft.RecoveryServices/vaults@2018-01-10' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource omsWorkspaceName 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsWorkspaceName_var
  location: 'East US'
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {}
}

resource vaultName_microsoft_insights_omsWorkspaceName 'Microsoft.RecoveryServices/vaults/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${vaultName}/microsoft.insights/${omsWorkspaceName_var}'
  properties: {
    name: omsWorkspaceName_var
    storageAccountId: storageAccountName.id
    workspaceId: omsWorkspaceName.id
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
}