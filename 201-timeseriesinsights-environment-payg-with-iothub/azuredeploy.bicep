@description('Determines whether or not a new IoT Hub should be provisioned.')
param iotHubNewOrExisting string = 'new'

@description('If you have an existing IotHub provide the name here. Defaults to the same resource group as the TSI environnment.')
param iotHubResourceGroup string = resourceGroup().name

@description('The name of the source IoT hub.')
param iotHubName string = 'tsi${uniqueString(resourceGroup().id)}'

@allowed([
  'F1'
  'S1'
  'S2'
  'S3'
  'B1'
  'B2'
  'B3'
])
@description('The name of the IoT hub Sku.')
param iotHubSku string = 'S1'

@description('The billing tier for the IoT hub.')
param iotHubSkuTier string = 'Standard'

@description('The name of the consumer group that the Time Series Insights service will use to read the data from the event hub. NOTE: To avoid resource contention, this consumer group must be dedicated to the Time Series Insights service and not shared with other readers.')
param consumerGroupName string = 'tsiquickstart'

@maxLength(90)
@description('Name of the environment. The name cannot include:   \'<\', \'>\', \'%\', \'&\', \':\', \'\\\', \'?\', \'/\' and any control characters. All other characters are allowed.')
param environmentName string = 'tsiquickstart'

@maxLength(90)
@description('An optional friendly name to show in tooling or user interfaces instead of the environment name.')
param environmentDisplayName string = 'tsiquickstart'

@allowed([
  'L1'
])
@description('The name of the sku. For more information, see https://azure.microsoft.com/pricing/details/time-series-insights/')
param environmentSkuName string = 'L1'

@allowed([
  'LongTerm'
])
@description('The Time Series Environment kind.')
param environmentKind string = 'LongTerm'

@minValue(1)
@maxValue(10)
@description('The unit capacity of the Sku. For more information, see https://azure.microsoft.com/pricing/details/time-series-insights/')
param environmentSkuCapacity int = 1

@maxLength(3)
@description('Time Series ID acts as a partition key for your data and as a primary key for your time series model. It is important that you specify the appropriate Time Series Property ID during environment creation, since you can\'t change it later. Note that the Property ID is case sensitive. You can use 1-3 keys: one is required, but up to three can be used to create a composite.')
param environmentTimeSeriesIdProperties array

@maxLength(90)
@description('Name of the event source child resource. The name cannot include:   \'<\', \'>\', \'%\', \'&\', \':\', \'\\\', \'?\', \'/\' and any control characters. All other characters are allowed.')
param eventSourceName string = 'tsiquickstart'

@maxLength(90)
@description('An optional friendly name to show in tooling or user interfaces instead of the event source name.')
param eventSourceDisplayName string = 'tsiquickstart'

@maxLength(90)
@description('The event property that will be used as the event source\'s timestamp. If a value isn\'t specified for timestampPropertyName, or if null or empty-string is specified, the event creation time will be used.')
param eventSourceTimestampPropertyName string = ''

@description('The name of the shared access key that the Time Series Insights service will use to connect to the event hub.')
param eventSourceKeyName string = 'service'

@description('A list of object ids of the users or applications in AAD that should have Reader access to the environment. The service principal objectId can be obtained by calling the Get-AzureRMADUser or the Get-AzureRMADServicePrincipal cmdlets. Creating an access policy for AAD groups is not yet supported.')
param accessPolicyReaderObjectIds array = []

@description('A list of object ids of the users or applications in AAD that should have Contributor access to the environment. The service principal objectId can be obtained by calling the Get-AzureRMADUser or the Get-AzureRMADServicePrincipal cmdlets. Creating an access policy for AAD groups is not yet supported.')
param accessPolicyContributorObjectIds array = []

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
@description('Storage Account type for L1 TSI environments.')
param storageAccountType string = 'Standard_LRS'

@description('ISO duration between 7 and 31 days. Remove the \'warmStoreConfiguration\' property from the envrionment to delete the warm store.')
param warmStoreDataRetention string = 'P7D'

var environmentTagsValue = {
  displayName: environmentDisplayName
}
var eventSourceTagsValue = {
  displayName: eventSourceDisplayName
}
var eventSourceResourceId = resourceId(iotHubResourceGroup, 'Microsoft.Devices/IotHubs', iotHubName)
var storageAccountName_var = 'tsi${uniqueString(resourceGroup().id)}'

resource iotHubName_resource 'Microsoft.Devices/IotHubs@2020-03-01' = if (iotHubNewOrExisting == 'new') {
  name: iotHubName
  location: location
  sku: {
    name: iotHubSku
    tier: iotHubSkuTier
    capacity: 1
  }
}

resource iotHubName_events_consumerGroupName 'Microsoft.Devices/iotHubs/eventhubEndpoints/ConsumerGroups@2020-03-01' = if (iotHubNewOrExisting == 'new') {
  name: '${iotHubName}/events/${consumerGroupName}'
  dependsOn: [
    iotHubName_resource
  ]
}

resource environmentName_resource 'Microsoft.TimeSeriesInsights/environments@2018-08-15-preview' = {
  name: environmentName
  location: location
  kind: environmentKind
  tags: environmentTagsValue
  properties: {
    storageConfiguration: {
      accountName: storageAccountName_var
      managementKey: listKeys(storageAccountName.id, '2019-06-01').keys[0].value
    }
    timeSeriesIdProperties: environmentTimeSeriesIdProperties
    warmStoreConfiguration: {
      dataRetention: warmStoreDataRetention
    }
  }
  sku: {
    name: environmentSkuName
    capacity: environmentSkuCapacity
  }
}

resource environmentName_eventSourceName 'Microsoft.TimeSeriesInsights/environments/eventsources@2018-08-15-preview' = {
  parent: environmentName_resource
  name: '${eventSourceName}'
  location: location
  kind: 'Microsoft.IoTHub'
  tags: eventSourceTagsValue
  properties: {
    eventSourceResourceId: eventSourceResourceId
    iotHubName: iotHubName
    consumerGroupName: consumerGroupName
    keyName: eventSourceKeyName
    sharedAccessKey: listkeys(resourceId('Microsoft.Devices/IoTHubs/IotHubKeys', iotHubName, eventSourceKeyName), '2020-03-01').primaryKey
    timestampPropertyName: eventSourceTimestampPropertyName
  }
  dependsOn: [
    iotHubName_resource
    iotHubName_events_consumerGroupName
  ]
}

resource environmentName_readerAccessPolicy 'Microsoft.TimeSeriesInsights/environments/accesspolicies@2018-08-15-preview' = [for i in range(0, (empty(accessPolicyReaderObjectIds) ? 1 : length(accessPolicyReaderObjectIds))): if (!empty(accessPolicyReaderObjectIds)) {
  name: '${environmentName}/readerAccessPolicy${i}'
  properties: {
    principalObjectId: accessPolicyReaderObjectIds[i]
    roles: [
      'Reader'
    ]
  }
  dependsOn: [
    environmentName_resource
  ]
}]

resource environmentName_contributorAccessPolicy 'Microsoft.TimeSeriesInsights/environments/accesspolicies@2018-08-15-preview' = [for i in range(0, (empty(accessPolicyContributorObjectIds) ? 1 : length(accessPolicyContributorObjectIds))): if (!empty(accessPolicyContributorObjectIds)) {
  name: '${environmentName}/contributorAccessPolicy${i}'
  properties: {
    principalObjectId: accessPolicyContributorObjectIds[i]
    roles: [
      'Contributor'
    ]
  }
  dependsOn: [
    environmentName_resource
  ]
}]

resource storageAccountName 'Microsoft.Storage/storageAccounts@2018-11-01' = if (environmentKind == 'LongTerm') {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

output dataAccessFQDN string = environmentName_resource.properties.dataAccessFQDN