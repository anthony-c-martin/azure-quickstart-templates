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

@description('Name or IP address of FTP server.')
param ftpHost string

@description('User account that has access to the FTP server.')
param ftpUser string

@description('Password for the user account that has access to the FTP server.')
param ftpPassword string

@description('The folder in FTP that has the input file.')
param ftpFolderName string

@description('Name of the input file in FTP.')
param ftpFileName string

@description('The folder in the blob container that will hold the transformed data.')
param outputBlobFolder string

@description('The folder in the blob container that contains the Hive query file.')
param hiveScriptFolder string

@description('Name of the hive query (HQL) file.')
param hiveScriptFile string

@description('Name of the Azure SQL Server that will hold the output/copied data.')
param sqlServerName string

@description('Name of the Azure SQL Database in the Azure SQL server.')
param sqlDatabaseName string

@description('Name of the user that has access to the Azure SQL server.')
param sqlServerUserName string

@description('Password for the user.')
@secure()
param sqlServerPassword string

@description('Table in the Azure SQL Database that will hold the copied data.')
param targetSQLTable string

var dataFactoryName_var = 'HiveTransformDF${uniqueString(resourceGroup().id)}'
var azureStorageLinkedServiceName = 'AzureStorageLinkedService'
var ftpLinkedServiceName = 'FTPLinkedService'
var hdInsightOnDemandLinkedServiceName = 'HDInsightOnDemandLinkedService'
var azureSqlLinkedServiceName = 'AzureSqlLinkedService'
var ftpDatasetName = 'FTPDataset'
var blobInputDatasetName = 'AzureBlobInputDataset'
var blobOutputDatasetName = 'AzureBlobOutputDataset'
var sqlDatasetName = 'AzureSQLDataset'
var pipelineName = 'Pipeline'

resource dataFactoryName 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName_var
  location: 'West US'
}

resource dataFactoryName_ftpLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${ftpLinkedServiceName}'
  properties: {
    type: 'FtpServer'
    typeProperties: {
      host: ftpHost
      port: 21
      authenticationType: 'Basic'
      username: ftpUser
      password: ftpPassword
      enableSsl: false
      enableServerCertificateValidation: false
    }
  }
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

resource dataFactoryName_azureSqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${azureSqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL linked service'
    typeProperties: {
      connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};User ID=${sqlServerUserName};Password=${sqlServerPassword};Trusted_Connection=False;Encrypt=True;Connection Timeout=30'
    }
  }
}

resource dataFactoryName_ftpDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${ftpDatasetName}'
  properties: {
    type: 'FileShare'
    linkedServiceName: ftpLinkedServiceName
    typeProperties: {
      folderPath: ftpFolderName
      fileName: ftpFileName
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: true
  }
  dependsOn: [
    dataFactoryName_ftpLinkedServiceName
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
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
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
      frequency: 'Day'
      interval: 1
    }
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_sqlDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${sqlDatasetName}'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: azureSqlLinkedServiceName
    typeProperties: {
      tableName: targetSQLTable
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    policy: {}
  }
  dependsOn: [
    dataFactoryName_azureSqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/datapipelines@2015-10-01' = {
  parent: dataFactoryName
  name: '${pipelineName}'
  properties: {
    description: 'Pipeline that copies data from an FTP server to Azure Blobs, invokes a hive script on an on-demand HDInsightcluster to transform the data'
    activities: [
      {
        type: 'Copy'
        name: 'FTPToBlobCopy'
        typeProperties: {
          source: {
            type: 'FileSystemSource'
            recursive: false
          }
          sink: {
            type: 'BlobSink'
            copyBehavior: 'PreserveHierarchy'
            writeBatchSize: 0
            writeBatchTimeout: '00:00:00'
          }
        }
        inputs: [
          {
            name: ftpDatasetName
          }
        ]
        outputs: [
          {
            name: blobInputDatasetName
          }
        ]
        policy: {
          concurrency: 1
          executionPriorityOrder: 'NewestFirst'
          retry: 1
          timeout: '00:05:00'
        }
      }
      {
        type: 'HDInsightHive'
        typeProperties: {
          scriptPath: '${blobContainer}/${hiveScriptFolder}/${hiveScriptFile}'
          scriptLinkedService: azureStorageLinkedServiceName
          defines: {
            inputtable: concat(replace(reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2016-01-01').primaryEndpoints.blob, 'https://', 'wasb://${blobContainer}@'), inputBlobFolder)
            outputtable: concat(replace(reference(resourceId(storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts/', storageAccountName), '2016-01-01').primaryEndpoints.blob, 'https://', 'wasb://${blobContainer}@'), outputBlobFolder)
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
        name: 'RunSampleHiveActivity'
        linkedServiceName: hdInsightOnDemandLinkedServiceName
      }
      {
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
            name: blobOutputDatasetName
          }
        ]
        outputs: [
          {
            name: sqlDatasetName
          }
        ]
        policy: {
          timeout: '1.00:00:00'
          concurrency: 1
          executionPriorityOrder: 'NewestFirst'
          style: 'StartOfInterval'
          retry: 3
          longRetry: 0
          longRetryInterval: '00:00:00'
        }
        name: 'BlobToSqlCopy'
      }
    ]
    start: '10/1/2015 12:00:00 AM'
    end: '10/2/2015 12:00:00 AM'
    isPaused: false
  }
  dependsOn: [
    dataFactoryName_azureStorageLinkedServiceName
    dataFactoryName_hdInsightOnDemandLinkedServiceName
    dataFactoryName_ftpLinkedServiceName
    dataFactoryName_azureSqlLinkedServiceName
    dataFactoryName_ftpDatasetName
    dataFactoryName_blobInputDatasetName
    dataFactoryName_blobOutputDatasetName
    dataFactoryName_sqlDatasetName
  ]
}