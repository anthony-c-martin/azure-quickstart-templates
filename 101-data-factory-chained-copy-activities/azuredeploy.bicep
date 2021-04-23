@description('URI of Azure Data Lake store')
param dataLakeStoreUri string

@description('ID of Azure Service Principal used for accessing Data Lake')
param dataLakeStoreServicePrincipalID string

@description('Key for Azure Service Principal used for accessing Data Lake')
@secure()
param dataLakeStoreServicePrincipalKey string

@description('Connection string for Azure SQL Database')
@secure()
param azureSQLConnectionString string

@description('Location for all resources.')
param location string = resourceGroup().location

var dataFactoryName_var = 'CopyFromSQLToADFToAzureSQL${uniqueString(resourceGroup().id)}'
var gatewayName = 'Gateway${uniqueString(resourceGroup().id)}'
var dataLakeLinkedServiceName = 'DataFactoryLinkedService'
var sqlLinkedServiceName = 'SqlLinkedService'
var azureSqlLinkedServiceName = 'AzureSqlLinkedService'
var dataLakeDatasetName = 'DataLakeDataset'
var sqlDatasetName = 'SqlDataset'
var azureSqlDatasetName = 'AzureSqlDataset'
var pipelineName = 'CopyFromSQLToADFToAzureSQLPipeline'

resource dataFactoryName 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName_var
  location: location
}

resource dataFactoryName_gatewayName 'Microsoft.DataFactory/datafactories/gateways@2015-10-01' = {
  parent: dataFactoryName
  name: '${gatewayName}'
  properties: {
    description: 'ADF on-premises Data Management Gateway'
  }
}

resource dataFactoryName_dataLakeLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${dataLakeLinkedServiceName}'
  properties: {
    type: 'AzureDataLakeStore'
    typeProperties: {
      dataLakeStoreUri: dataLakeStoreUri
      servicePrincipalId: dataLakeStoreServicePrincipalID
      servicePrincipalKey: dataLakeStoreServicePrincipalKey
      tenant: subscription().tenantId
      subscriptionId: subscription().subscriptionId
      resourceGroupName: resourceGroup().name
    }
  }
}

resource dataFactoryName_sqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${sqlLinkedServiceName}'
  properties: {
    type: 'OnPremisesSqlServer'
    typeProperties: {
      connectionString: 'Placeholder-COnnectionString-Replace-Post-Deployment'
      gatewayName: gatewayName
      userName: ''
      password: '**********'
    }
  }
  dependsOn: [
    dataFactoryName_gatewayName
  ]
}

resource dataFactoryName_azureSqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  parent: dataFactoryName
  name: '${azureSqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: azureSQLConnectionString
    }
  }
}

resource dataFactoryName_dataLakeDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${dataLakeDatasetName}'
  properties: {
    structure: [
      {
        name: 'CurrencyCode'
        type: 'string'
      }
      {
        name: 'Name'
        type: 'string'
      }
      {
        name: 'ModifiedDate'
        type: 'Datetime'
      }
    ]
    published: false
    type: 'AzureDataLakeStore'
    linkedServiceName: dataLakeLinkedServiceName
    typeProperties: {
      fileName: 'data.orc'
      folderPath: '${dataFactoryName_var}/{year}/{month}/{day}/{hour}/{minute}/'
      format: {
        type: 'OrcFormat'
      }
      partitionedBy: [
        {
          name: 'year'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'yy'
          }
        }
        {
          name: 'month'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'MM'
          }
        }
        {
          name: 'day'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'dd'
          }
        }
        {
          name: 'hour'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'HH'
          }
        }
        {
          name: 'minute'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'mm'
          }
        }
      ]
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: false
    policy: {}
  }
  dependsOn: [
    dataFactoryName_dataLakeLinkedServiceName
  ]
}

resource dataFactoryName_sqlDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${sqlDatasetName}'
  properties: {
    structure: [
      {
        name: 'CurrencyCode'
        type: 'string'
      }
      {
        name: 'Name'
        type: 'string'
      }
      {
        name: 'ModifiedDate'
        type: 'Datetime'
      }
    ]
    published: false
    type: 'SqlServerTable'
    linkedServiceName: sqlLinkedServiceName
    typeProperties: {
      tableName: 'Sales.Currency'
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: true
    policy: {}
  }
  dependsOn: [
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_azureSqlDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  parent: dataFactoryName
  name: '${azureSqlDatasetName}'
  properties: {
    structure: [
      {
        name: 'CurrencyCode'
        type: 'string'
      }
      {
        name: 'Name'
        type: 'string'
      }
      {
        name: 'ModifiedDate'
        type: 'Datetime'
      }
    ]
    published: false
    type: 'AzureSqlTable'
    linkedServiceName: azureSqlLinkedServiceName
    typeProperties: {
      tableName: 'Sales.Currency'
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: false
    policy: {}
  }
  dependsOn: [
    dataFactoryName_azureSqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/dataPipelines@2015-10-01' = {
  parent: dataFactoryName
  name: '${pipelineName}'
  properties: {
    activities: [
      {
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'SqlSource'
            sqlReaderQuery: '$$Text.Format(\'select * from Sales.Currency where ModifiedDate >= \\\'{0:yyyy-MM-dd HH:mm}\\\' AND ModifiedDate < \\\'{1:yyyy-MM-dd HH:mm}\\\'\', WindowStart, WindowEnd)'
          }
          sink: {
            type: 'AzureDataLakeStoreSink'
            writeBatchSize: 0
            writeBatchTimeout: '00:00:00'
          }
        }
        inputs: [
          {
            name: sqlDatasetName
          }
        ]
        outputs: [
          {
            name: dataLakeDatasetName
          }
        ]
        policy: {
          timeout: '1.00:00:00'
          concurrency: 10
          executionPriorityOrder: 'NewestFirst'
          style: 'StartOfInterval'
          retry: 3
          longRetry: 0
          longRetryInterval: '00:00:00'
        }
        scheduler: {
          frequency: 'Day'
          interval: 1
        }
        name: 'Activity-OnPremSQL->ADL'
      }
      {
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'AzureDataLakeStoreSource'
            recursive: false
          }
          sink: {
            type: 'SqlSink'
            sqlWriterCleanupScript: '$$Text.Format(\'delete [Sales].[Currency] where [ModifiedDate] >= \\\'{0:yyyy-MM-dd HH:mm}\\\' AND [ModifiedDate] <\\\'{1:yyyy-MM-dd HH:mm}\\\'\', WindowStart, WindowEnd)'
            writeBatchSize: 0
            writeBatchTimeout: '00:00:00'
          }
          translator: {
            type: 'TabularTranslator'
            columnMappings: 'CurrencyCode:CurrencyCode,ModifiedDate:ModifiedDate,Name:Name'
          }
        }
        inputs: [
          {
            name: dataLakeDatasetName
          }
        ]
        outputs: [
          {
            name: azureSqlDatasetName
          }
        ]
        policy: {
          timeout: '1.00:00:00'
          concurrency: 10
          executionPriorityOrder: 'NewestFirst'
          style: 'StartOfInterval'
          retry: 3
          longRetry: 0
          longRetryInterval: '00:00:00'
        }
        scheduler: {
          frequency: 'Day'
          interval: 1
        }
        name: 'Activity-ADL->AzureSQL'
      }
    ]
    start: '8/16/2017 12:00:00 AM'
    end: '8/16/2099 12:00:00 AM'
    isPaused: true
    pipelineMode: 'Scheduled'
  }
  dependsOn: [
    dataFactoryName_dataLakeLinkedServiceName
    dataFactoryName_sqlLinkedServiceName
    dataFactoryName_azureSqlLinkedServiceName
    dataFactoryName_dataLakeDatasetName
  ]
}