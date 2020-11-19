param eventHubNamespaceName string {
  metadata: {
    description: 'Name of the EventHub namespace'
  }
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
param captureEnabled string {
  allowed: [
    'false'
    'true'
  ]
  metadata: {
    description: 'Enable or disable the Capture feature for your Event Hub'
  }
  default: 'true'
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
param captureNameFormat string {
  metadata: {
    description: 'A Capture Name Format must contain {Namespace}, {EventHub}, {PartitionId}, {Year}, {Month}, {Day}, {Hour}, {Minute} and {Second} fields. These can be arranged in any order with or without delimeters. E.g.  Prod_{EventHub}/{Namespace}\\{PartitionId}_{Year}_{Month}/{Day}/{Hour}/{Minute}/{Second}'
  }
  default: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
}
param subscriptionId string {
  metadata: {
    description: 'Subscription Id of both Data Lake Store and Event Hub namespace'
  }
}
param dataLakeAccountName string {
  metadata: {
    description: 'Data Lake Store name'
  }
}
param dataLakeFolderPath string {
  metadata: {
    description: 'Destination archive folder path'
  }
}

var defaultSASKeyName = 'RootManageSharedAccessKey'
var authRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', eventHubNamespaceName, defaultSASKeyName)

resource eventHubNamespaceName_res 'Microsoft.EventHub/Namespaces@2017-04-01' = {
  name: eventHubNamespaceName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource eventHubNamespaceName_eventHubName 'Microsoft.EventHub/Namespaces/eventhubs@2017-04-01' = {
  name: '${eventHubNamespaceName}/${eventHubName}'
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