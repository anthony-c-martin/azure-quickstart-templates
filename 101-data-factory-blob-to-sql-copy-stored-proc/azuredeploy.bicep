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
param sqlDatabaseName string {
  metadata: {
    description: 'Name of Azure SQL Database in Azure SQL server copying data to.'
  }
}
param sqlUserID string {
  metadata: {
    description: 'Username for access to Azure SQL Server.'
  }
}
param sqlPassword string {
  metadata: {
    description: 'Password for the user to Azure SQL Server.'
  }
  secure: true
}
param sqlTargetTable string {
  metadata: {
    description: 'Table in the Azure SQL Database that will hold the copied data.'
  }
}
param sqlWriterTableType string {
  metadata: {
    description: 'Specify a table type name to be used in the stored procedure. Copy activity makes the data being moved available in a temp table with this table type.'
  }
}
param sqlWriterStoredProcedureName string {
  metadata: {
    description: 'Name of the stored procedure that upserts (updates/inserts) data into the target table.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var dataFactoryName = 'CopyFromAzureBlobToAzureSQLDbSproc${uniqueString(resourceGroup().id)}'
var storageLinkedServiceName = 'StorageLinkedService'
var sqlLinkedServiceName = 'SqlLinkedService'
var storageDataset = 'StorageDataset'
var intermediateDataset = 'IntermediateDataset'
var sqlDataset = 'SqlDataset'
var pipelineName = 'BlobtoSqlDbCopyPipelineSproc'

resource dataFactoryName_resource 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName
  location: location
}

resource dataFactoryName_storageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${storageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage Linked Service'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_sqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${sqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL linked service'
    typeProperties: {
      connectionString: 'Data Source=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabaseName};Integrated Security=False;User ID=${sqlUserID};Password=${sqlPassword};Connect Timeout=30;Encrypt=True'
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_storageDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${storageDataset}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: storageLinkedServiceName
    typeProperties: {
      folderPath: '${sourceBlobContainer}/'
      fileName: sourceBlobName
      format: {
        type: 'TextFormat'
      }
    }
    availability: {
      frequency: 'Hour'
      interval: 1
    }
    external: true
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_intermediateDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${intermediateDataset}'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: sqlLinkedServiceName
    typeProperties: {
      tableName: intermediateDataset
    }
    availability: {
      frequency: 'Hour'
      interval: 1
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_sqlDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${sqlDataset}'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: sqlLinkedServiceName
    typeProperties: {
      tableName: sqlTargetTable
    }
    availability: {
      frequency: 'Hour'
      interval: 1
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/dataPipelines@2015-10-01' = {
  name: '${dataFactoryName}/${pipelineName}'
  properties: {
    description: 'Copies data from Azure Blob to Sql DB while invoking stored procedure'
    activities: [
      {
        name: 'BlobtoSqlTableCopyActivity'
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BlobSource'
          }
          sink: {
            type: 'SqlSink'
            writeBatchSize: 0
            writeBatchTimeout: '00:00:00'
          }
        }
        inputs: [
          {
            name: storageDataset
          }
        ]
        outputs: [
          {
            name: intermediateDataset
          }
        ]
      }
      {
        name: 'SqlTabletoSqlDbSprocActivity'
        type: 'SqlServerStoredProcedure'
        inputs: [
          {
            name: intermediateDataset
          }
        ]
        outputs: [
          {
            name: sqlDataset
          }
        ]
        typeProperties: {
          storedProcedureName: sqlWriterStoredProcedureName
        }
        scheduler: {
          frequency: 'Hour'
          interval: 1
        }
        policy: {
          timeout: '02:00:00'
          concurrency: 1
          executionPriorityOrder: 'NewestFirst'
          retry: 3
        }
      }
    ]
    start: '10/1/2016 12:00:00 AM'
    end: '10/2/2016 12:00:00 AM'
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
    dataFactoryName_sqlLinkedServiceName
    dataFactoryName_storageDataset
    dataFactoryName_sqlDataset
  ]
}