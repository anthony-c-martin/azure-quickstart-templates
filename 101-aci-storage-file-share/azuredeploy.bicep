@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'

@description('Storage Account Name')
param storageAccountName string = uniqueString(resourceGroup().id)

@description('File Share Name')
param fileShareName string

@description('Container Instance Location')
param containerInstanceLocation string = location

@description('Location for all resources.')
param location string = resourceGroup().location

var image = 'microsoft/azure-cli'
var cpuCores = '1.0'
var memoryInGb = '1.5'
var containerGroupName_var = 'createshare-containerinstance'
var containerName = 'createshare'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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
    storageAccountName_resource
  ]
}