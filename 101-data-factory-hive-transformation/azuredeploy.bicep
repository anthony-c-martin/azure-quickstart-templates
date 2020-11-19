param storageAccountResourceGroupName string {
  metadata: {
    description: 'The resource group that contains your Azure storage account that contains the input/output data.'
  }
}
param storageAccountName string {
  metadata: {
    description: 'Name of the Azure storage account that contains the input/output data.'
  }
}
param storageAccountKey string {
  metadata: {
    description: 'Key for the Azure storage account.'
  }
  secure: true
}
param blobContainer string {
  metadata: {
    description: 'Name of the blob container in the Azure Storage account.'
  }
}
param inputBlobFolder string {
  metadata: {
    description: 'The folder in the blob container that has the input file.'
  }
}
param inputBlobName string {
  metadata: {
    description: 'Name of the input file/blob.'
  }
}
param outputBlobFolder string {
  metadata: {
    description: 'The folder in the blob container that will hold the transformed data.'
  }
}
param hiveScriptFolder string {
  metadata: {
    description: 'The folder in the blob container that contains the Hive query file.'
  }
}
param hiveScriptFile string {
  metadata: {
    description: 'Name of the hive query (HQL) file.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var dataFactoryName = 'HiveTransformDF${uniqueString(resourceGroup().id)}'
var azureStorageLinkedServiceName = 'AzureStorageLinkedService'
var hdInsightOnDemandLinkedServiceName = 'HDInsightOnDemandLinkedService'
var blobInputDatasetName = 'AzureBlobInput'
var blobOutputDatasetName = 'AzureBlobOutput'
var pipelineName = 'HiveTransformPipeline'

resource dataFactoryName_resource 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName
  location: location
}

resource dataFactoryName_azureStorageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${azureStorageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage linked service'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_hdInsightOnDemandLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${hdInsightOnDemandLinkedServiceName}'
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
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_blobInputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${blobInputDatasetName}'
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
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_blobOutputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${blobOutputDatasetName}'
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
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/datapipelines@2015-10-01' = {
  name: '${dataFactoryName}/${pipelineName}'
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
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
    dataFactoryName_hdInsightOnDemandLinkedServiceName
    dataFactoryName_blobInputDatasetName
    dataFactoryName_blobOutputDatasetName
  ]
}