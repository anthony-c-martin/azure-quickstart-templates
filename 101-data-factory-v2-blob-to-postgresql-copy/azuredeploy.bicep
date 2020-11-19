param dataFactoryName string {
  metadata: {
    description: 'Name of the data factory. Must be globally unique.'
  }
  default: uniqueString(resourceGroup().id)
}
param location string {
  metadata: {
    description: 'Location of the data factory.'
  }
  default: resourceGroup().location
}
param storageAccountResourceId string {
  metadata: {
    description: 'Resource ID of Source Azure Storage account.'
  }
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
param postgreSqlResourceId string {
  metadata: {
    description: 'Resource ID of target Azure Database for PostgreSQL Server.'
  }
}
param postgreSqlUserName string {
  metadata: {
    description: 'UserName of the target Azure Database for PostgreSQL Server.'
  }
}
param postgreSqlPassword string {
  metadata: {
    description: 'Password of the target Azure Database for PostgreSQL Server.'
  }
  secure: true
}
param postgreSqlDatabase string {
  metadata: {
    description: 'Name of the target database in the Azure Database for PostgreSQL.'
  }
  default: 'postgres'
}
param postgreSqlTableName string {
  metadata: {
    description: 'Name of the target table in the Azure Database for PostgreSQL.'
  }
}

var azureStorageLinkedServiceName = 'Tutorial2-AzureStorageLinkedService'
var azurePostgreSqlDatabaseLinkedServiceName = 'Tutorial2-AzurePostgreSqlDatabaseLinkedService'
var inputDatasetName = 'Tutorial2_InputBlobDataset'
var outputDatasetName = 'Tutorial2_OutputPostgreSqlDataset'
var pipelineName = 'Tutorial2-CopyFromBlobToPostgreSqlPipeline'

resource dataFactoryName_res 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  properties: {}
}

resource dataFactoryName_azureStorageLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${dataFactoryName}/${azureStorageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage linked service'
    typeProperties: {
      connectionString: {
        value: 'DefaultEndpointsProtocol=https;AccountName=${split(split(reference(storageAccountResourceId, '2019-04-01').primaryEndpoints.blob, '/')[2], '.')[0]};AccountKey=${listKeys(storageAccountResourceId, '2019-04-01').keys[0].value}'
        type: 'SecureString'
      }
    }
  }
}

resource dataFactoryName_azurePostgreSqlDatabaseLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${dataFactoryName}/${azurePostgreSqlDatabaseLinkedServiceName}'
  properties: {
    type: 'AzurePostgreSql'
    description: 'Azure Database for PostgreSQL linked service'
    typeProperties: {
      connectionString: {
        value: 'Server=${reference(postgreSqlResourceId, '2017-12-01').fullyQualifiedDomainName};Port=5432;Database=${postgreSqlDatabase};UID=${postgreSqlUserName};Password=${postgreSqlPassword};SSL Mode=Require'
        type: 'SecureString'
      }
    }
  }
}

resource dataFactoryName_inputDatasetName 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactoryName}/${inputDatasetName}'
  properties: {
    type: 'AzureBlob'
    structure: [
      {
        name: 'firstname'
        type: 'string'
      }
      {
        name: 'lastname'
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

resource dataFactoryName_outputDatasetName 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactoryName}/${outputDatasetName}'
  properties: {
    type: 'AzurePostgreSqlTable'
    typeProperties: {
      tableName: postgreSqlTableName
    }
    linkedServiceName: {
      referenceName: azurePostgreSqlDatabaseLinkedServiceName
      type: 'LinkedServiceReference'
    }
  }
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
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
            type: 'AzurePostgreSqlSink'
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