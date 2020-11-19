param existingStorageAcctResourceId string {
  metadata: {
    description: 'Name of the exiting Storage Account to archieve captures'
  }
}
param eventHubNamespaceName string {
  metadata: {
    description: 'Name of the EventHub namespace'
  }
}
param eventhubSku string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'The messaging tier for service Bus namespace'
  }
  default: 'Standard'
}
param skuCapacity int {
  allowed: [
    1
    2
    4
  ]
  metadata: {
    description: 'MessagingUnits for premium namespace'
  }
  default: 1
}
param isAutoInflateEnabled string {
  allowed: [
    'True'
    'False'
  ]
  metadata: {
    description: 'Enable or disable AutoInflate'
  }
  default: 'True'
}
param maximumThroughputUnits int {
  minValue: 0
  maxValue: 20
  metadata: {
    description: 'Upper limit of throughput units when AutoInflate is enabled, vaule should be within 0 to 20 throughput units.'
  }
  default: 10
}
param eventHubName string {
  metadata: {
    description: 'Name of the Event Hub'
  }
}
param messageRetentionInDays int {
  minValue: 1
  maxValue: 7
  metadata: {
    description: 'How long to retain the data in Event Hub'
  }
  default: 1
}
param partitionCount int {
  minValue: 2
  maxValue: 32
  metadata: {
    description: 'Number of partitions chosen'
  }
  default: 4
}
param captureEnabled bool {
  metadata: {
    description: 'Enable or disable the Capture feature for your Event Hub'
  }
  default: true
}
param captureEncodingFormat string {
  allowed: [
    'Avro'
  ]
  metadata: {
    description: 'The encoding format Eventhub capture serializes the EventData when archiving to your storage'
  }
  default: 'Avro'
}
param captureTime int {
  minValue: 60
  maxValue: 900
  metadata: {
    description: 'the time window in seconds for the archival'
  }
  default: 300
}
param captureSize int {
  minValue: 10485760
  maxValue: 524288000
  metadata: {
    description: 'the size window in bytes for evetn hub capture'
  }
  default: 314572800
}
param blobContainerName string {
  metadata: {
    description: 'Your existing storage container that you want the blobs archived in'
  }
}
param captureNameFormat string {
  metadata: {
    description: 'A Capture Name Format must contain {Namespace}, {EventHub}, {PartitionId}, {Year}, {Month}, {Day}, {Hour}, {Minute} and {Second} fields. These can be arranged in any order with or without delimeters. E.g.  Prod_{EventHub}/{Namespace}\\{PartitionId}_{Year}_{Month}/{Day}/{Hour}/{Minute}/{Second}'
  }
  default: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId_var = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, defaultSASKeyName)

resource eventHubNamespaceName_res 'Microsoft.EventHub/Namespaces@2018-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: eventhubSku
    tier: eventhubSku
    capacity: skuCapacity
  }
  tags: {
    tag1: 'value1'
    tag2: 'value2'
  }
  properties: {
    isAutoInflateEnabled: isAutoInflateEnabled
    maximumThroughputUnits: maximumThroughputUnits
  }
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/Namespaces/eventhubs@2017-04-01' = {
  name: '${eventHubNamespaceName}/${eventHubName}'
  properties: {
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
    captureDescription: {
      enabled: captureEnabled
      skipEmptyArchives: false
      encoding: captureEncodingFormat
      intervalInSeconds: captureTime
      sizeLimitInBytes: captureSize
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: existingStorageAcctResourceId
          blobContainer: blobContainerName
          archiveNameFormat: captureNameFormat
        }
      }
    }
  }
}

output authRuleResourceId string = authRuleResourceId_var