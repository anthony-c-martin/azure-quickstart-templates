@description('The resource group that contains your Azure storage account that contains the input/output data.')
param storageAccountResourceGroupName string

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string

@description('Key for the Azure storage account.')
@secure()
param storageAccountKey string

@description('Name of the blob container in the Azure Storage account.')
param blobContainer string

@description('The folder in the blob container that has the input file.')
param inputBlobFolder string

@description('Name of the input file/blob.')
param inputBlobName string

@description('The folder in the blob container that will hold the transformed data.')
param outputBlobFolder string

@description('The folder in the blob container that contains the Hive query file.')
param hiveScriptFolder string

@description('Name of the hive query (HQL) file.')
param hiveScriptFile string

@description('Location for all resources.')
param location string = resourceGroup().location

var dataFactoryName_var = 'HiveTransformDF${uniqueString(resourceGroup().id)}'
var azureStorageLinkedServiceName = 'AzureStorageLinkedService'
var hdInsightOnDemandLinkedServiceName = 'HDInsightOnDemandLinkedService'
var blobInputDatasetName = 'AzureBlobInput'
var blobOutputDatasetName = 'AzureBlobOutput'
var pipelineName = 'HiveTransformPipeline'

resource dataFactoryName 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName_var
  location: location
}

resource dataFactoryName_azureStorageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${azureStorageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage linked service'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
}

resource dataFactoryName_hdInsightOnDemandLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${hdInsightOnDemandLinkedServiceName}'
  properties: {
    type: 'HDInsightOnDemand'
    typeProperties: {
      clusterSize: 1
      version: '3.2'
      timeToLive: '00:05:00'
      osType: 'windows'
      linkedServiceName: azureStorageLinkedServiceName
    }
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_blobInputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${blobInputDatasetName}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: azureStorageLinkedServiceName
    typeProperties: {
      fileName: inputBlobName
      folderPath: '${blobContainer}/${inputBlobFolder}'
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
      }
    }
    availability: {
      frequency: 'Month'
      interval: 1
    }
    external: true
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_blobOutputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${blobOutputDatasetName}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: azureStorageLinkedServiceName
    typeProperties: {
      folderPath: '${blobContainer}/${outputBlobFolder}'
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
      }
    }
    availability: {
      frequency: 'Month'
      interval: 1
    }
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/datapipelines@2015-10-01' = {
  parent: dataFactoryName
  name: '${pipelineName}'
  properties: {
    description: 'Pipeline that transforms data using Hive script.'
    activities: [
      {
        type: 'HDInsightHive'
        typeProperties: {
          scriptPath: '${blobContainer}/${hiveScriptFolder}/${hiveScriptFile}'
          scriptLinkedService: azureStorageLinkedServiceName
          defines: {
            inputtable: concat(replace(reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2016-01-01').primaryEndpoints.blob, 'https://', 'wasb://${blobContainer}@'), inputBlobFolder)
            partitionedtable: concat(replace(reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2016-01-01').primaryEndpoints.blob, 'https://', 'wasb://${blobContainer}@'), outputBlobFolder)
          }
        }
        inputs: [
          {
            name: blobInputDatasetName
          }
        ]
        outputs: [
          {
            name: blobOutputDatasetName
          }
        ]
        policy: {
          concurrency: 1
          retry: 2
        }
        scheduler: {
          frequency: 'Month'
          interval: 1
        }
        name: 'RunSampleHiveActivity'
        linkedServiceName: hdInsightOnDemandLinkedServiceName
      }
    ]
    start: '9/1/2016 12:00:00 AM'
    end: '9/2/2016 12:00:00 AM'
    isPaused: false
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
    dataFactoryName_hdInsightOnDemandLinkedServiceName
    dataFactoryName_blobInputDatasetName
    dataFactoryName_blobOutputDatasetName
  ]
}