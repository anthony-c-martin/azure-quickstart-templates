param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'Storage Account type'
  }
  default: 'Standard_LRS'
}
param storageAccountName string {
  metadata: {
    description: 'Storage Account Name'
  }
  default: uniqueString(resourceGroup().id)
}
param fileShareName string {
  metadata: {
    description: 'File Share Name'
  }
}
param containerInstanceLocation string {
  metadata: {
    description: 'Container Instance Location'
  }
  default: location
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var image = 'microsoft/azure-cli'
var cpuCores = '1.0'
var memoryInGb = '1.5'
var containerGroupName_var = 'createshare-containerinstance'
var containerName = 'createshare'

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource containerGroupName 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: containerGroupName_var
  location: containerInstanceLocation
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: image
          command: [
            'az'
            'storage'
            'share'
            'create'
            '--name'
            fileShareName
          ]
          environmentVariables: [
            {
              name: 'AZURE_STORAGE_KEY'
              value: listKeys(storageAccountName, '2019-06-01').keys[0].value
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccountName
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
  }
  dependsOn: [
    storageAccountName_res
  ]
}