param storageAccountName string {
  metadata: {
    description: 'Name of the Azure storage account that contains the data to be copied.'
  }
}
param storageAccountKey string {
  metadata: {
    description: 'Key for the Azure storage account.'
  }
  secure: true
}
param sourceBlobContainer string {
  metadata: {
    description: 'Name of the blob container in the Azure Storage account.'
  }
}
param sourceBlobName string {
  metadata: {
    description: 'Name of the blob in the container that has the data to be copied to Azure SQL Database table'
  }
}
param sqlServerName string {
  metadata: {
    description: 'Name of the Azure SQL Server that will hold the output/copied data.'
  }
}
param databaseName string {
  metadata: {
    description: 'Name of the Azure SQL Database in the Azure SQL server.'
  }
}
param sqlServerUserName string {
  metadata: {
    description: 'Name of the user that has access to the Azure SQL server.'
  }
}
param sqlServerPassword string {
  metadata: {
    description: 'Password for the user.'
  }
  secure: true
}
param targetSQLTable string {
  metadata: {
    description: 'Table in the Azure SQL Database that will hold the copied data.'
  }
}

var dataFactoryName = 'AzureBlobToAzureSQLDatabaseDF${uniqueString(resourceGroup().id)}'
var azureSqlLinkedServiceName = 'AzureSqlLinkedService'
var azureStorageLinkedServiceName = 'AzureStorageLinkedService'
var blobInputDatasetName = 'BlobInputDataset'
var sqlOutputDatasetName = 'SQLOutputDataset'
var pipelineName = 'Blob2SQLPipeline'

resource dataFactoryName_resource 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName
  location: 'West US'
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

resource dataFactoryName_azureSqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${azureSqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL linked service'
    typeProperties: {
      connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Database=${databaseName};User ID=${sqlServerUserName};Password=${sqlServerPassword};Trusted_Connection=False;Encrypt=True;Connection Timeout=30'
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_blobInputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${blobInputDatasetName}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: azureStorageLinkedServiceName
    structure: [
      {
        name: 'Column0'
        type: 'string'
      }
      {
        name: 'Column1'
        type: 'string'
      }
    ]
    typeProperties: {
      folderPath: '${sourceBlobContainer}/'
      fileName: sourceBlobName
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
      }
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: true
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_sqlOutputDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${sqlOutputDatasetName}'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: azureSqlLinkedServiceName
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
      tableName: targetSQLTable
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_azureSqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/datapipelines@2015-10-01' = {
  name: '${dataFactoryName}/${pipelineName}'
  properties: {
    activities: [
      {
        name: 'CopyFromAzureBlobToAzureSQL'
        description: 'Copy data frm Azure blob to Azure SQL'
        type: 'Copy'
        inputs: [
          {
            name: blobInputDatasetName
          }
        ]
        outputs: [
          {
            name: sqlOutputDatasetName
          }
        ]
        typeProperties: {
          source: {
            type: 'BlobSource'
          }
          sink: {
            type: 'SqlSink'
            sqlWriterCleanupScript: '$$Text.Format(\'DELETE FROM {0}\', \'emp\')'
          }
          translator: {
            type: 'TabularTranslator'
            columnMappings: 'Column0:FirstName,Column1:LastName'
          }
        }
        Policy: {
          concurrency: 1
          executionPriorityOrder: 'NewestFirst'
          retry: 3
          timeout: '01:00:00'
        }
      }
    ]
    start: '10/3/2016 12:00:00 AM'
    end: '10/4/2016 12:00:00 AM'
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_azureStorageLinkedServiceName
    dataFactoryName_azureSqlLinkedServiceName
    dataFactoryName_blobInputDatasetName
    dataFactoryName_sqlOutputDatasetName
  ]
}