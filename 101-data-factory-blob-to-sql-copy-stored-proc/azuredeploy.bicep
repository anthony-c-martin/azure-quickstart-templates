@description('Name of the Azure storage account that contains the data to be copied.')
param storageAccountName string

@description('Key for the Azure storage account.')
@secure()
param storageAccountKey string

@description('Name of the blob container in the Azure Storage account.')
param sourceBlobContainer string

@description('Name of the blob in the container that has the data to be copied to Azure SQL Database table')
param sourceBlobName string

@description('Name of the Azure SQL Server that will hold the output/copied data.')
param sqlServerName string

@description('Name of Azure SQL Database in Azure SQL server copying data to.')
param sqlDatabaseName string

@description('Username for access to Azure SQL Server.')
param sqlUserID string

@description('Password for the user to Azure SQL Server.')
@secure()
param sqlPassword string

@description('Table in the Azure SQL Database that will hold the copied data.')
param sqlTargetTable string

@description('Specify a table type name to be used in the stored procedure. Copy activity makes the data being moved available in a temp table with this table type.')
param sqlWriterTableType string

@description('Name of the stored procedure that upserts (updates/inserts) data into the target table.')
param sqlWriterStoredProcedureName string

@description('Location for all resources.')
param location string = resourceGroup().location

var dataFactoryName_var = 'CopyFromAzureBlobToAzureSQLDbSproc${uniqueString(resourceGroup().id)}'
var storageLinkedServiceName = 'StorageLinkedService'
var sqlLinkedServiceName = 'SqlLinkedService'
var storageDataset = 'StorageDataset'
var intermediateDataset = 'IntermediateDataset'
var sqlDataset = 'SqlDataset'
var pipelineName = 'BlobtoSqlDbCopyPipelineSproc'

resource dataFactoryName 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName_var
  location: location
}

resource dataFactoryName_storageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${storageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Storage Linked Service'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
}

resource dataFactoryName_sqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${sqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL linked service'
    typeProperties: {
      connectionString: 'Data Source=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabaseName};Integrated Security=False;User ID=${sqlUserID};Password=${sqlPassword};Connect Timeout=30;Encrypt=True'
    }
  }
}

resource dataFactoryName_storageDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${storageDataset}'
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
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_intermediateDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${intermediateDataset}'
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
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_sqlDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${sqlDataset}'
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
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/dataPipelines@2015-10-01' = {
  parent: dataFactoryName
  name: '${pipelineName}'
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
    dataFactoryName_storageLinkedServiceName
    dataFactoryName_sqlLinkedServiceName
    dataFactoryName_storageDataset
    dataFactoryName_sqlDataset
  ]
}