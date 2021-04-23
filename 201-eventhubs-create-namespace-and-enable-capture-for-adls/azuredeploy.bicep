@description('Name of the EventHub namespace')
param eventHubNamespaceName string

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

@allowed([
  'false'
  'true'
])
@description('Enable or disable the Capture feature for your Event Hub')
param captureEnabled string = 'true'

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

@description('A Capture Name Format must contain {Namespace}, {EventHub}, {PartitionId}, {Year}, {Month}, {Day}, {Hour}, {Minute} and {Second} fields. These can be arranged in any order with or without delimeters. E.g.  Prod_{EventHub}/{Namespace}\\{PartitionId}_{Year}_{Month}/{Day}/{Hour}/{Minute}/{Second}')
param captureNameFormat string = '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'

@description('Subscription Id of both Data Lake Store and Event Hub namespace')
param subscriptionId string

@description('Data Lake Store name')
param dataLakeAccountName string

@description('Destination archive folder path')
param dataLakeFolderPath string

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, defaultSASKeyName)

resource eventHubNamespaceName_resource 'Microsoft.EventHub/Namespaces@2017-04-01' = {
  name: eventHubNamespaceName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/Namespaces/eventhubs@2017-04-01' = {
  parent: eventHubNamespaceName_resource
  name: '${eventHubName}'
  properties: {
    path: eventHubName
    captureDescription: {
      enabled: true
      skipEmptyArchives: false
      encoding: captureEncodingFormat
      intervalInSeconds: captureTime
      sizeLimitInBytes: captureSize
      destination: {
        name: 'EventHubArchive.AzureDataLake'
        properties: {
          DataLakeSubscriptionId: subscriptionId
          DataLakeAccountName: dataLakeAccountName
          DataLakeFolderPath: dataLakeFolderPath
          archiveNameFormat: captureNameFormat
        }
      }
    }
  }
}

output NamespaceConnectionString string = listkeys(authRuleResourceId, '2017-04-01').primaryConnectionString
output SharedAccessPolicyPrimaryKey string = listkeys(authRuleResourceId, '2017-04-01').primaryKey