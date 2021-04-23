@description('The location in which the resources will be created.Check supported locations')
param location string = resourceGroup().location

@description('Name of the EventHub namespace')
param eventHubNamespaceName string = toLower('yashEventHubns${uniqueString(resourceGroup().id)}')

@minValue(60)
@maxValue(900)
@description('the time window in seconds for the archival')
param captureTime int = 300

@minValue(10485760)
@maxValue(524288000)
@description('the size window in bytes for event hub capture')
param captureSize int = 10485760

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

@minValue(1)
@maxValue(7)
@description('How long to retain the data in Event Hub')
param messageRetentionInDays int = 1

@minValue(2)
@maxValue(32)
@description('Number of partitions chosen')
param partitionCount int = 2

@allowed([
  'Avro'
])
@description('The encoding format Eventhub capture serializes the EventData when archiving to your storage')
param captureEncodingFormat string = 'Avro'

@description('The name of the Data Lake Analytics account to create.')
param adlAnalyticsName string = toLower('yashadlaa${uniqueString(resourceGroup().id)}')

@description('The name of the Data Lake Store account to create.')
param adlStoreName string = toLower('yashadls1a${uniqueString(resourceGroup().id)}')

@description('Size of vm Eg. Standard_D1_v2')
param vmSize string = 'Standard_D1_v2'

@description('Username for the Virtual Machine.')
param vm_username string

@description('Password for the Virtual Machine.')
@secure()
param vm_password string

@allowed([
  'Yes'
  'No'
])
@description('Select whether the VM should be in production or not.')
param OptionalWizardInstall string = 'Yes'

@description('Name of the data factory. Must be globally unique.')
param dataFactoryName string = toLower('yashdf${uniqueString(resourceGroup().id)}')

@description('Name of the Azure datalake UI app registered. Must be globally unique.')
param appName string = toLower('azuredatalakeuiappa${uniqueString(resourceGroup().id)}')

@description('The ID of the service principal that has permissions to create HDInsight clusters in your subscription.')
param servicePrincipalId string = 'null'

@description('The access key of the service principal that has permissions to create HDInsight clusters in your subscription.')
@secure()
param servicePrincipalKey string = ''

@allowed([
  'East US 2'
  'North Europe'
  'Central US'
  'West Europe'
  'Australia East'
])
@description('The location in which the resources will be created.Check supported locations')
param dataLakeAnalyticsLocation string = 'East US 2'

@description('The base URI where artifacts required by this template are located here')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/yash-datalake/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var storageAccountName = toLower('storagea${uniqueString(resourceGroup().id)}')
var blobContainer = 'raw'
var storageAccountType = 'Standard_LRS'
var maximumThroughputUnits = 8
var DataCleaningInputStream = 'datalakerawstreama'
var DataCleaningOutputStream = 'datalakecleanstreama'
var captureNameFormat = '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
var DataCleaningStreamAnalyticsJob = 'cleanOrdersStreamAnalyticsJoba'
var DataAggregatorStreamAnalyticsJob1 = 'sellingProductPerMinJoba'
var DataAggregatorStreamAnalyticsJob2 = 'geoLocationsJoba'
var DataAggregatorStreamAnalyticsJob3 = 'ageGroupWiseRevenueJoba'
var dnsLabelPrefix = 'datalake${uniqueString(resourceGroup().id, deployment().name)}'
var ES_Function_name = toLower('elkstackFn${uniqueString(resourceGroup().id)}')
var serverfarms_name = toLower('elkstackASP${uniqueString(resourceGroup().id)}')
var config_web_name_4 = 'web'
var artloc = 'https://azbotstorage.blob.core.windows.net/sample-artifacts/yash-datalake-2/'

module storageAccount '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/storageAccount.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'storageAccount'
  params: {
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
    location: location
  }
}

module dataFactory '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/dataFactory.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'dataFactory'
  params: {
    KibanaESDeployedVMIP: reference('KibanaESDeployedVM').outputs.publicIpAddress.value
    storageAccountName: storageAccountName
    '_artifactsLocation': artloc
    '_artifactsLocationSasToken': artifactsLocationSasToken
    dataFactoryName: dataFactoryName
    dataFactoryLocation: location
    blobContainer: blobContainer
    servicePrincipalId: servicePrincipalId
    servicePrincipalKey: servicePrincipalKey
  }
  dependsOn: [
    KibanaESDeployedVM
  ]
}

module dataLakeAnalytics '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/datalakeAnalytics.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'dataLakeAnalytics'
  params: {
    adlAnalyticsName: adlAnalyticsName
    adlStoreName: adlStoreName
    storageAccountName: storageAccountName
    dataLakeAnalyticsLocation: dataLakeAnalyticsLocation
  }
  dependsOn: [
    storageAccount
  ]
}

module EventHubTemplate '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/eventHub.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'EventHubTemplate'
  params: {
    eventHubNamespaceName: eventHubNamespaceName
    location: location
    eventhubSku: eventhubSku
    skuCapacity: skuCapacity
    isAutoInflateEnabled: isAutoInflateEnabled
    maximumThroughputUnits: maximumThroughputUnits
    DataCleaningInputStream: DataCleaningInputStream
    DataCleaningOutputStream: DataCleaningOutputStream
    messageRetentionInDays: messageRetentionInDays
    partitionCount: partitionCount
    captureEncodingFormat: captureEncodingFormat
    captureTime: captureTime
    captureSize: captureSize
    storageAccountName: storageAccountName
    captureNameFormat: captureNameFormat
  }
  dependsOn: [
    dataLakeAnalytics
  ]
}

module streamAnalyticsJobsTemplate '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/streamAnalytics.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'streamAnalyticsJobsTemplate'
  params: {
    eventHubNamespaceName: eventHubNamespaceName
    location: location
    DataCleaningInputStream: DataCleaningInputStream
    DataCleaningOutputStream: DataCleaningOutputStream
    storageAccountName: storageAccountName
    DataCleaningStreamAnalyticsJob: DataCleaningStreamAnalyticsJob
    DataAggregatorStreamAnalyticsJob1: DataAggregatorStreamAnalyticsJob1
    DataAggregatorStreamAnalyticsJob2: DataAggregatorStreamAnalyticsJob2
    DataAggregatorStreamAnalyticsJob3: DataAggregatorStreamAnalyticsJob3
  }
  dependsOn: [
    EventHubTemplate
  ]
}

module azureFunction '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/azureFunction.json', parameters('_artifactsLocationSasToken')))]*/ = if (OptionalWizardInstall == 'Yes') {
  name: 'azureFunction'
  params: {
    KibanaESDeployedVMIP: reference('KibanaESDeployedVM').outputs.publicIpAddress.value
    storageAccountName: storageAccountName
    appName: appName
    location: location
    web_app_id: servicePrincipalId
    web_app_secret: servicePrincipalKey
    datafactory_name: dataFactoryName
    eventhub_name: DataCleaningInputStream
    eventhub_namespace: eventHubNamespaceName
    adla_account_name: adlAnalyticsName
    DataCleaningStreamAnalyticsJob: DataCleaningStreamAnalyticsJob
    DataAggregatorStreamAnalyticsJob1: DataAggregatorStreamAnalyticsJob1
    DataAggregatorStreamAnalyticsJob2: DataAggregatorStreamAnalyticsJob2
    DataAggregatorStreamAnalyticsJob3: DataAggregatorStreamAnalyticsJob3
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    KibanaESDeployedVM
    EventHubTemplate
  ]
}

module KibanaESDeployedVM '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/elasticSearchKibana.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'KibanaESDeployedVM'
  params: {
    vmSize: vmSize
    username: vm_username
    password: vm_password
    dnsLabelPrefix: dnsLabelPrefix
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    storageAccount
  ]
}

module KibanaFunctionApp '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'),concat('nested/blobTriggerdFunction.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'KibanaFunctionApp'
  params: {
    storage_name: storageAccountName
    kibanaFunctionHost: ES_Function_name
    kibanaFunctionPath: '/api/AddKibanaDashboard'
    EsIP: reference('KibanaESDeployedVM').outputs.publicIpAddress.value
    serverfarms_name: serverfarms_name
    sites_demotriggerapp1234_name: ES_Function_name
    location: location
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    config_web_name_4: config_web_name_4
  }
  dependsOn: [
    KibanaESDeployedVM
  ]
}

output websiteUrl string = '${reference('azureFunction').outputs.websiteUrl.value}/api/quickstart_wizard'