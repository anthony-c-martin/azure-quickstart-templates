param projectName string {
  minLength: 1
  maxLength: 11
  metadata: {
    description: 'Define the project name or prefix for all objects.'
  }
  default: 'contoso'
}
param location string {
  metadata: {
    description: 'The datacenter to use for the deployment.'
  }
  default: resourceGroup().location
}
param skuName string {
  metadata: {
    description: 'The SKU to use for the IoT Hub.'
  }
  default: 'S1'
}
param skuUnits string {
  metadata: {
    description: 'The number of IoT Hub units.'
  }
  default: '1'
}
param d2cPartitions string {
  metadata: {
    description: 'Partitions used for the event stream.'
  }
  default: '4'
}

var iotHubName = '${projectName}Hub${uniqueString(resourceGroup().id)}'
var storageAccountName = concat(toLower(projectName), uniqueString(resourceGroup().id))
var storageEndpoint = '${projectName}StorageEndpont'
var storageContainerName = '${toLower(projectName)}results'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  properties: {}
}

resource storageAccountName_default_storageContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName}/default/${storageContainerName}'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

resource IoTHubName_resource 'Microsoft.Devices/IotHubs@2020-07-10-preview' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: d2cPartitions
      }
    }
    routing: {
      endpoints: {
        storageContainers: [
          {
            connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountName_resource.id, '2019-06-01').keys[0].value}'
            containerName: storageContainerName
            fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}'
            batchFrequencyInSeconds: 100
            maxChunkSizeInBytes: 104857600
            encoding: 'json'
            name: storageEndpoint
          }
        ]
      }
      routes: [
        {
          name: 'ContosoStorageRoute'
          source: 'DeviceMessages'
          condition: 'level="storage"'
          endpointNames: [
            storageEndpoint
          ]
          isEnabled: true
        }
      ]
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: false
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
  }
  dependsOn: [
    storageAccountName_resource
  ]
}