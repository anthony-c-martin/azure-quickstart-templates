@description('Name of the data factory. Must be globally unique.')
param dataFactoryName string

@allowed([
  'East US'
  'East US 2'
  'West Europe'
  'Southeast Asia'
])
@description('Location of the data factory.')
param dataFactoryLocation string

@description('Connnection string for the on-premsies SQL Server database.')
param onPremSqlServerConnectionString string

@description('Name of the target table in the Azure SQL database.')
param sqlTableName string

@description('Connection string for the Azure Storage account.')
@secure()
param azureStorageConnectionString string

@description('Name of the blob container in the Azure Storage account.')
param blobContainer string

@description('The folder in the blob container to which the data is copied.')
param outputBlobFolder string

var azureStorageLinkedServiceName = 'Tutorial3-AzureStorageLinkedService'
var selfHostedIRName = 'Tutorial3-SelfHostedIR'
var onPremSqlServerLinkedServiceName = 'Tutorial3-OnPremSqlServerLinkedService'
var inputDatasetName = 'Tutorial3-InputBlobDataset'
var outputDatasetName = 'Tutorial3-OutputSqlDataset'
var pipelineName = 'Tutorial3-CopyFromOnPremSqlToBlobPipeline'

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2017-09-01-preview' = {
  name: dataFactoryName
  location: dataFactoryLocation
  properties: {}
}

resource dataFactoryName_azureStorageLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${azureStorageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage linked service'
    typeProperties: {
      connectionString: {
        value: azureStorageConnectionString
        type: 'SecureString'
      }
    }
  }
}

resource dataFactoryName_selfHostedIRName 'Microsoft.DataFactory/factories/integrationRuntimes@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${selfHostedIRName}'
  properties: {
    type: 'SelfHosted'
  }
}

resource dataFactoryName_onPremSqlServerLinkedServiceName 'Microsoft.DataFactory/factories/linkedServices@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${onPremSqlServerLinkedServiceName}'
  properties: {
    type: 'SqlServer'
    typeProperties: {
      connectionString: {
        type: 'SecureString'
        value: onPremSqlServerConnectionString
      }
    }
    connectVia: {
      referenceName: selfHostedIRName
      type: 'IntegrationRuntimeReference'
    }
  }
  dependsOn: [
    dataFactoryName_selfHostedIRName
  ]
}

resource dataFactoryName_inputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${inputDatasetName}'
  properties: {
    linkedServiceName: {
      referenceName: onPremSqlServerLinkedServiceName
      type: 'LinkedServiceReference'
    }
    type: 'SqlServerTable'
    typeProperties: {
      tableName: sqlTableName
    }
  }
  dependsOn: [
    dataFactoryName_onPremSqlServerLinkedServiceName
  ]
}

resource dataFactoryName_outputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${outputDatasetName}'
  properties: {
    linkedServiceName: {
      referenceName: azureStorageLinkedServiceName
      type: 'LinkedServiceReference'
    }
    type: 'AzureBlob'
    typeProperties: {
      fileName: '@CONCAT(pipeline().RunId, \'.txt\')'
      folderPath: '${blobContainer}\\${outputBlobFolder}'
    }
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/factories/pipelines@2017-09-01-preview' = {
  parent: dataFactoryName_resource
  name: '${pipelineName}'
  properties: {
    activities: [
      {
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BlobSource'
            recursive: true
          }
          sink: {
            type: 'SqlSink'
            writeBatchSize: 10000
          }
        }
        name: 'MyCopyActivity'
        inputs: [
          {
            referenceName: inputDatasetName
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: outputDatasetName
            type: 'DatasetReference'
          }
        ]
      }
    ]
  }
  dependsOn: [
    dataFactoryName_inputDatasetName
    dataFactoryName_outputDatasetName
  ]
}