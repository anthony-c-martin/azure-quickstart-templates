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
  default: 'East US'
}
param AzureStorage_connectionString string {
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
param AzureSqlDatabase_connectionString string {
  metadata: {
    description: 'Connnection string for the Azure SQL database.'
  }
}
param sqlTableName string {
  metadata: {
    description: 'Name of the target table in the Azure SQL database.'
  }
}

var azureStorageLinkedServiceName = 'Tutorial2-AzureStorageLinkedService'
var azureSqlDatabaseLinkedServiceName = 'Tutorial2-AzureSqlDatabaseLinkedService'
var inputDatasetName = 'Tutorial2-InputBlobDataset'
var outputDatasetName = 'Tutorial2-OutputSqlDataset'
var pipelineName = 'Tutorial2-CopyFromBlobToSqlPipeline'

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
        value: AzureStorage_connectionString
        type: 'SecureString'
      }
    }
  }
}

resource dataFactoryName_azureSqlDatabaseLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${azureSqlDatabaseLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL Database linked service'
    typeProperties: {
      connectionString: {
        value: AzureSqlDatabase_connectionString
        type: 'SecureString'
      }
    }
  }
}

resource dataFactoryName_inputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${inputDatasetName}'
  properties: {
    type: 'AzureBlob'
    structure: [
      {
        name: 'Prop_0'
        type: 'string'
      }
      {
        name: 'Prop_1'
        type: 'string'
      }
    ]
    typeProperties: {
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
        nullValue: '\\N'
        treatEmptyAsNull: false
        firstRowAsHeader: false
      }
      folderPath: '${blobContainer}/${inputBlobFolder}/'
      fileName: inputBlobName
    }
    linkedServiceName: {
      referenceName: azureStorageLinkedServiceName
      type: 'LinkedServiceReference'
    }
  }
}

resource dataFactoryName_outputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${outputDatasetName}'
  properties: {
    type: 'AzureSqlTable'
    structure: [
      {
        name: 'FirstName'
        type: 'string'
      }
      {
        name: 'LastName'
        type: 'string'
      }
    ]
    typeProperties: {
      tableName: sqlTableName
    }
    linkedServiceName: {
      referenceName: azureSqlDatabaseLinkedServiceName
      type: 'LinkedServiceReference'
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