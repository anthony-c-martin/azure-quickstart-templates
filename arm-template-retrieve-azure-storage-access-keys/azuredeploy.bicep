param storageAccountName string {
  metadata: {
    description: 'Name of the Azure Storage account.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param storageAccountSku string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
    'Premium_LRS'
    'Premium_ZRS'
    'Standard_GZRS'
    'Standard_RAGZRS'
  ]
  metadata: {
    description: 'Sku on which to run the Azure Storage account.'
  }
  default: 'Standard_LRS'
}
param storageAccountKind string {
  allowed: [
    'Storage'
    'StorageV2'
    'BlobStorage'
    'FileStorage'
    'BlockBlobStorage'
  ]
  metadata: {
    description: 'Indicates the type of storage account.'
  }
  default: 'StorageV2'
}
param storageAccountContainerName string {
  metadata: {
    description: 'Set the name of the container to create in the Storage account.'
  }
  default: 'my-container'
}
param storageConnectionName string {
  metadata: {
    description: 'Name of the Logic Apps API connection used to connect to the Azure Storage account.'
  }
  default: 'storageconnection${uniqueString(resourceGroup().id)}'
}
param logicAppName string {
  metadata: {
    description: 'Name of the Logic App.'
  }
  default: 'logicapp${uniqueString(resourceGroup().id)}'
}
param logicAppPollingIntervalInMinutes int {
  metadata: {
    description: 'The polling interval used to check for items on the Storage account.'
  }
  default: 30
}
param location string {
  metadata: {
    description: 'Location where resources reside.'
  }
  default: resourceGroup().location
}

var storageAccountId = storageAccountName_resource.id

resource storageConnectionName_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: storageConnectionName
  location: location
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
    }
    parameterValues: {
      accountName: storageAccountName
      accessKey: listKeys(storageAccountId, '2019-04-01').keys[0].value
    }
    testLinks: [
      {
        requestUri: uri('https://management.azure.com:443/', 'subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${storageConnectionName}/extensions/proxy/testconnection?api-version=2018-07-01-preview')
        method: 'get'
      }
    ]
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_blob_is_added_or_modified_(properties_only)': {
          recurrence: {
            frequency: 'Minute'
            interval: logicAppPollingIntervalInMinutes
          }
          splitOn: '@triggerBody()'
          metadata: {
            JTJmbXktY29udGFpbmVy: '/${storageAccountContainerName}'
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/datasets/default/triggers/batch/onupdatedfile'
            queries: {
              folderId: 'JTJmbXktY29udGFpbmVy'
              maxFileCount: 10
            }
          }
        }
      }
      actions: {
        Process_blobs: {
          type: 'Scope'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: storageConnectionName_resource.id
            connectionName: 'azureblob'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
          }
        }
      }
    }
    state: 'Enabled'
  }
  dependsOn: [
    storageConnectionName_resource
  ]
}