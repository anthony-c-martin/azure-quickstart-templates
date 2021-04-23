@description('Ex- inforp2ptest')
param sqlDWServerName string

@description('The location where all azure resources will be deployed.')
param location string = 'eastus'

@description('SQL Datawarehouse Database Name')
param sqlDWDBName string

@description('Sql Data Warehouse User Name')
param sqlDWDBAdminName string

@description('Sql Data Warehouse Password')
@secure()
param sqlDWAdminPassword string

@description('Name of the data factory. It must be globally unique')
param dataFactoryName string

@description('Start time of the data slice. ex: 2014-06-01T18:00:00')
param start string

@description('end time of the data slice. ex: 2014-06-01T18:00:00')
param end string
param tableName string = 'bi9'
param inputFolderPath string = 'adfgetstarted/inputdata'
param outputFolderPath string = 'adfgetstarted/inputdata'
param adfstorageAccountName string
param apiVersion string = '2015-10-01'
param storageLinkedServiceName string = 'AzureStorageLinkedService'
param hdInsightOnDemandLinkedServiceName string = 'HDInsightOnDemandLinkedService'
param azureSqlDWLinkedServiceName string = 'AzureSqlDWLinkedService'
param blobInputDataset string = 'AzureBlobInput'
param blobOutputDataset string = 'AzureBlobOutput'
param sqlDWOutputDataset string = 'AzureSqlDWOutput'
param azureSqlDWLinkedServiceConnectionString string = ''
param clusterSize int = 1
param version string = '3.2'
param timeToLive string = '00:45:00'
param frequency string = 'Hour'
param interval int = 1
param writeBatchSize int = 0
param writeBatchTimeout string = '00:00:00'
param timeout string = '01:00:00'
param script string = ''
param informaticaTags object
param quickstartTags object

var storageApiVersion = '2015-06-15'

resource dataFactoryName_resource 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName
  location: 'westus'
  tags: {
    displayName: 'VM Storage Accounts'
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
}

resource dataFactoryName_storageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${storageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${adfstorageAccountName};AccountKey=${listKeys(resourceId('Microsoft.Storage/storageAccounts', adfstorageAccountName), storageApiVersion).key1}'
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_hivestoredlinkedservice 'Microsoft.DataFactory/datafactories/linkedservices@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/hivestoredlinkedservice'
  properties: {
    type: 'AzureStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=hivestorage45;AccountKey=HxaJ9xKgO3/1PS5bRO6fc+rTdS+KXWhGsxLubXweQaw75qbFu3AWHwuR6IggpKZeXtspV+RYfffDtFBO5pMRXA=='
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_hdInsightOnDemandLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${hdInsightOnDemandLinkedServiceName}'
  properties: {
    type: 'HDInsightOnDemand'
    typeProperties: {
      clusterSize: clusterSize
      version: version
      timeToLive: timeToLive
      osType: 'windows'
      linkedServiceName: storageLinkedServiceName
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_azureSqlDWLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${azureSqlDWLinkedServiceName}'
  properties: {
    type: 'AzureSqlDW'
    typeProperties: {
      connectionString: azureSqlDWLinkedServiceConnectionString
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_blobInputDataset 'Microsoft.DataFactory/datafactories/datasets@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${blobInputDataset}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: storageLinkedServiceName
    typeProperties: {
      folderPath: inputFolderPath
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
      }
    }
    availability: {
      frequency: frequency
      interval: interval
    }
    external: true
    policy: {}
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_blobOutputDataset 'Microsoft.DataFactory/datafactories/datasets@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${blobOutputDataset}'
  properties: {
    published: false
    type: 'AzureBlob'
    linkedServiceName: storageLinkedServiceName
    typeProperties: {
      folderPath: outputFolderPath
      format: {
        type: 'TextFormat'
        columnDelimiter: ','
      }
    }
    availability: {
      frequency: frequency
      interval: interval
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_sqlDWOutputDataset 'Microsoft.DataFactory/datafactories/datasets@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${sqlDWOutputDataset}'
  properties: {
    published: false
    type: 'AzureSqlDWTable'
    linkedServiceName: azureSqlDWLinkedServiceName
    typeProperties: {
      tableName: tableName
    }
    availability: {
      frequency: frequency
      interval: interval
    }
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_azureSqlDWLinkedServiceName
  ]
}

resource dataFactoryName_dataFactoryName 'Microsoft.DataFactory/datafactories/datapipelines@[parameters(\'apiVersion\')]' = {
  name: '${dataFactoryName}/${dataFactoryName}'
  properties: {
    description: 'My first Azure Data Factory pipeline'
    activities: [
      {
        type: 'HDInsightHive'
        typeProperties: {
          scriptPath: 'adfgetstarted/script/hiveinfop2p.hql'
          scriptLinkedService: 'hivestoredlinkedservice'
          defines: {
            inputtable: 'wasb://adfgetstarted@${adfstorageAccountName}.blob.core.windows.net/inputdata'
            partitionedtable: 'wasb://adfgetstarted@${adfstorageAccountName}.blob.core.windows.net/partitioneddata'
          }
        }
        inputs: [
          {
            name: 'AzureBlobInput'
          }
        ]
        outputs: [
          {
            name: 'AzureBlobOutput'
          }
        ]
        policy: {
          concurrency: 1
          retry: 3
        }
        scheduler: {
          frequency: frequency
          interval: interval
        }
        name: 'RunSampleHiveActivity'
        linkedServiceName: 'HDInsightOnDemandLinkedService'
      }
      {
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BlobSource'
          }
          sink: {
            type: 'SqlDWSink'
            writeBatchSize: writeBatchSize
            writeBatchTimeout: writeBatchTimeout
          }
        }
        inputs: [
          {
            name: 'AzureBlobOutput'
          }
        ]
        outputs: [
          {
            name: 'AzureSqlDWOutput'
          }
        ]
        policy: {
          timeout: timeout
          concurrency: 1
        }
        scheduler: {
          frequency: frequency
          interval: interval
        }
        name: 'AzureBlobtoSQLDW'
        description: 'Copy Activity'
      }
    ]
    start: start
    end: end
    isPaused: false
  }
  dependsOn: [
    dataFactoryName_resource
    dataFactoryName_storageLinkedServiceName
    dataFactoryName_hdInsightOnDemandLinkedServiceName
    dataFactoryName_azureSqlDWLinkedServiceName
    dataFactoryName_blobInputDataset
    dataFactoryName_blobOutputDataset
    dataFactoryName_sqlDWOutputDataset
  ]
}

output ucpConsoleAddress string = script