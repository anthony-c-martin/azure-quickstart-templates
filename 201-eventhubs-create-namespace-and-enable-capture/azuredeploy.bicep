@description('Name of the exiting Storage Account to archieve captures')
param existingStorageAcctResourceId string

@description('Name of the EventHub namespace')
param eventHubNamespaceName string

@allowed([
  'Basic'
  'Standard'
])
@description('The messaging tier for service Bus namespace')
param eventhubSku string = 'Standard'

@allowed([
  1
  2
  4
])
@description('MessagingUnits for premium namespace')
param skuCapacity int = 1

@allowed([
  'True'
  'False'
])
@description('Enable or disable AutoInflate')
param isAutoInflateEnabled string = 'True'

@minValue(0)
@maxValue(20)
@description('Upper limit of throughput units when AutoInflate is enabled, vaule should be within 0 to 20 throughput units.')
param maximumThroughputUnits int = 10

@description('Name of the Event Hub')
param eventHubName string

@minValue(1)
@maxValue(7)
@description('How long to retain the data in Event Hub')
param messageRetentionInDays int = 1

@minValue(2)
@maxValue(32)
@description('Number of partitions chosen')
param partitionCount int = 4

@description('Enable or disable the Capture feature for your Event Hub')
param captureEnabled bool = true

@allowed([
  'Avro'
])
@description('The encoding format Eventhub capture serializes the EventData when archiving to your storage')
param captureEncodingFormat string = 'Avro'

@minValue(60)
@maxValue(900)
@description('the time window in seconds for the archival')
param captureTime int = 300

@minValue(10485760)
@maxValue(524288000)
@description('the size window in bytes for evetn hub capture')
param captureSize int = 314572800

@description('Your existing storage container that you want the blobs archived in')
param blobContainerName string

@description('A Capture Name Format must contain {Namespace}, {EventHub}, {PartitionId}, {Year}, {Month}, {Day}, {Hour}, {Minute} and {Second} fields. These can be arranged in any order with or without delimeters. E.g.  Prod_{EventHub}/{Namespace}\\{PartitionId}_{Year}_{Month}/{Day}/{Hour}/{Minute}/{Second}')
param captureNameFormat string = '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'

@description('Location for all resources.')
param location string = resourceGroup().location

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, defaultSASKeyName)

resource eventHubNamespaceName_resource 'Microsoft.EventHub/Namespaces@2018-01-01-preview' = {
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
  parent: eventHubNamespaceName_resource
  name: '${eventHubName}'
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

output authRuleResourceId string = authRuleResourceId