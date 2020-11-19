param dataLakeStoreUri string {
  metadata: {
    description: 'URI of Azure Data Lake store'
  }
}
param dataLakeStoreServicePrincipalID string {
  metadata: {
    description: 'ID of Azure Service Principal used for accessing Data Lake'
  }
}
param dataLakeStoreServicePrincipalKey string {
  metadata: {
    description: 'Key for Azure Service Principal used for accessing Data Lake'
  }
  secure: true
}
param azureSQLConnectionString string {
  metadata: {
    description: 'Connection string for Azure SQL Database'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var dataFactoryName = 'CopyFromSQLToADFToAzureSQL${uniqueString(resourceGroup().id)}'
var gatewayName = 'Gateway${uniqueString(resourceGroup().id)}'
var dataLakeLinkedServiceName = 'DataFactoryLinkedService'
var sqlLinkedServiceName = 'SqlLinkedService'
var azureSqlLinkedServiceName = 'AzureSqlLinkedService'
var dataLakeDatasetName = 'DataLakeDataset'
var sqlDatasetName = 'SqlDataset'
var azureSqlDatasetName = 'AzureSqlDataset'
var pipelineName = 'CopyFromSQLToADFToAzureSQLPipeline'

resource dataFactoryName_resource 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName
  location: location
}

resource dataFactoryName_gatewayName 'Microsoft.DataFactory/datafactories/gateways@2015-10-01' = {
  name: '${dataFactoryName}/${gatewayName}'
  properties: {
    description: 'ADF on-premises Data Management Gateway'
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_dataLakeLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${dataLakeLinkedServiceName}'
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
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_sqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${sqlLinkedServiceName}'
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
    dataFactoryName_resource
    dataFactoryName_gatewayName
  ]
}

resource dataFactoryName_azureSqlLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName}/${azureSqlLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: azureSQLConnectionString
    }
  }
  dependsOn: [
    dataFactoryName_resource
  ]
}

resource dataFactoryName_dataLakeDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${dataLakeDatasetName}'
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
      folderPath: '${dataFactoryName}/{year}/{month}/{day}/{hour}/{minute}/'
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
    dataFactoryName_resource
    dataFactoryName_dataLakeLinkedServiceName
  ]
}

resource dataFactoryName_sqlDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${sqlDatasetName}'
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
    dataFactoryName_resource
    dataFactoryName_sqlLinkedServiceName
  ]
}

resource dataFactoryName_azureSqlDatasetName 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName}/${azureSqlDatasetName}'
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
    dataFactoryName_resource
    dataFactoryName_azureSqlLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/datafactories/dataPipelines@2015-10-01' = {
  name: '${dataFactoryName}/${pipelineName}'
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
    dataFactoryName_resource
    dataFactoryName_dataLakeLinkedServiceName
    dataFactoryName_sqlLinkedServiceName
    dataFactoryName_azureSqlLinkedServiceName
    dataFactoryName_dataLakeDatasetName
  ]
}