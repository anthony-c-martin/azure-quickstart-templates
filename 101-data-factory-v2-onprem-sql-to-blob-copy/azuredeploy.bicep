param dataFactoryName string {
  metadata: {
    description: 'Name of the data factory. Must be globally unique.'
  }
}
param dataFactoryLocation string {
  allowed: [
    'East US'
    'East US 2'
    'West Europe'
    'Southeast Asia'
  ]
  metadata: {
    description: 'Location of the data factory.'
  }
}
param onPremSqlServerConnectionString string {
  metadata: {
    description: 'Connnection string for the on-premsies SQL Server database.'
  }
}
param sqlTableName string {
  metadata: {
    description: 'Name of the target table in the Azure SQL database.'
  }
}
param azureStorageConnectionString string {
  metadata: {
    description: 'Connection string for the Azure Storage account.'
  }
  secure: true
}
param blobContainer string {
  metadata: {
    description: 'Name of the blob container in the Azure Storage account.'
  }
}
param outputBlobFolder string {
  metadata: {
    description: 'The folder in the blob container to which the data is copied.'
  }
}

var azureStorageLinkedServiceName = 'Tutorial3-AzureStorageLinkedService'
var selfHostedIRName = 'Tutorial3-SelfHostedIR'
var onPremSqlServerLinkedServiceName = 'Tutorial3-OnPremSqlServerLinkedService'
var inputDatasetName = 'Tutorial3-InputBlobDataset'
var outputDatasetName = 'Tutorial3-OutputSqlDataset'
var pipelineName = 'Tutorial3-CopyFromOnPremSqlToBlobPipeline'

resource dataFactoryName_res 'Microsoft.DataFactory/factories@2017-09-01-preview' = {
  name: dataFactoryName
  location: dataFactoryLocation
  properties: {}
}

resource dataFactoryName_azureStorageLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${azureStorageLinkedServiceName}'
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
  name: '${dataFactoryName}/${selfHostedIRName}'
  properties: {
    type: 'SelfHosted'
  }
}

resource dataFactoryName_onPremSqlServerLinkedServiceName 'Microsoft.DataFactory/factories/linkedServices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${onPremSqlServerLinkedServiceName}'
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
}

resource dataFactoryName_inputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${inputDatasetName}'
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
}

resource dataFactoryName_outputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${outputDatasetName}'
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
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/factories/pipelines@2017-09-01-preview' = {
  name: '${dataFactoryName}/${pipelineName}'
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
}