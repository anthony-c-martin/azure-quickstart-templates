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
param azureStorageConnectionString string {
  metadata: {
    description: 'Connection string for the Azure Storage account.'
  }
  secure: true
}
param azureSqlDatabaseConnectionString string {
  metadata: {
    description: 'Connnection string for the Azure SQL database.'
  }
}
param azureSqllDataWarehouseConnectionString string {
  metadata: {
    description: 'Connection string for the Azure SQL Data Warehouse'
  }
}

var azureStorageLinkedServiceName = 'Tutorial4_AzureStorageLinkedService'
var azureSqlDatabaseLinkedServiceName = 'Tutorial4_AzureSqlDatabaseLinkedService'
var azureSqlDataWareHouseLinkedServiceName = 'Tutorial4_AzureSqlDataWarehouseLinkedService'
var inputDatasetName = 'Tutorial4_InputSqlDataset'
var outputDatasetName = 'Tutorial4_OutputSqlDataWarehouseDataset'
var pipelineName = 'Tutorial2-CopyFromSqlToSqlDwPipeline'
var pipelineName2 = 'Tutorial2-TriggerCopyPipeline'
var leftBracket = '['

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
  dependsOn: [
    dataFactoryName_res
  ]
}

resource dataFactoryName_azureSqlDatabaseLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${azureSqlDatabaseLinkedServiceName}'
  properties: {
    type: 'AzureSqlDatabase'
    description: 'Azure SQL Database linked service'
    typeProperties: {
      connectionString: {
        value: azureSqlDatabaseConnectionString
        type: 'SecureString'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
  ]
}

resource dataFactoryName_azureSqlDataWarehouseLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${azureSqlDataWareHouseLinkedServiceName}'
  properties: {
    type: 'AzureSqlDW'
    description: 'Azure SQL Data Warehouse linked service'
    typeProperties: {
      connectionString: {
        value: azureSqllDataWarehouseConnectionString
        type: 'SecureString'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
  ]
}

resource dataFactoryName_inputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${inputDatasetName}'
  properties: {
    linkedServiceName: {
      referenceName: azureSqlDatabaseLinkedServiceName
      type: 'LinkedServiceReference'
    }
    type: 'AzureSqlTable'
    typeProperties: {
      tableName: '\'dummy\''
    }
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_azureSqlDatabaseLinkedServiceName
  ]
}

resource dataFactoryName_outputDatasetName 'Microsoft.DataFactory/factories/datasets@2017-09-01-preview' = {
  name: '${dataFactoryName}/${outputDatasetName}'
  properties: {
    linkedServiceName: {
      referenceName: azureSqlDataWareHouseLinkedServiceName
      type: 'LinkedServiceReference'
    }
    parameters: {
      DWTableName: {
        type: 'string'
      }
    }
    type: 'AzureSqlDWTable'
    typeProperties: {
      tableName: {
        value: '@{dataset().DWTableName}'
        type: 'Expression'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_azureSqlDataWarehouseLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/factories/pipelines@2017-09-01-preview' = {
  name: '${dataFactoryName}/${pipelineName}'
  properties: {
    activities: [
      {
        name: 'IterateSQLTables'
        description: ''
        type: 'ForEach'
        dependsOn: []
        typeProperties: {
          items: {
            value: '@pipeline().parameters.tableList'
            type: 'Expression'
          }
          activities: [
            {
              name: 'CopyData'
              type: 'Copy'
              dependsOn: []
              policy: {}
              typeProperties: {
                source: {
                  type: 'SqlSource'
                  sqlReaderQuery: 'SELECT * FROM [@{item().TABLE_SCHEMA}].[@{item().TABLE_NAME}]'
                }
                sink: {
                  type: 'SqlDWSink'
                  allowPolyBase: true
                  writeBatchSize: 10000
                  preCopyScript: 'TRUNCATE TABLE [@{item().TABLE_SCHEMA}].[@{item().TABLE_NAME}]'
                  polyBaseSettings: {
                    rejectValue: 0
                    rejectType: 'value'
                    useTypeDefault: false
                  }
                }
                enableStaging: true
                stagingSettings: {
                  linkedServiceName: {
                    referenceName: azureStorageLinkedServiceName
                    type: 'LinkedServiceReference'
                  }
                }
                cloudDataMovementUnits: 0
              }
              inputs: [
                {
                  referenceName: inputDatasetName
                  type: 'DatasetReference'
                  parameters: {}
                }
              ]
              outputs: [
                {
                  referenceName: outputDatasetName
                  type: 'DatasetReference'
                  parameters: {
                    DWTableName: '${leftBracket}@{item().TABLE_SCHEMA}].[@{item().TABLE_NAME}]'
                  }
                }
              ]
            }
          ]
        }
      }
    ]
    parameters: {
      tableList: {
        type: 'Array'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_inputDatasetName
    dataFactoryName_outputDatasetName
  ]
}

resource dataFactoryName_pipelineName2 'Microsoft.DataFactory/factories/pipelines@2017-09-01-preview' = {
  name: '${dataFactoryName}/${pipelineName2}'
  properties: {
    activities: [
      {
        name: 'LookupTableList'
        description: ' Retrieve the table list from Azure SQL database'
        type: 'Lookup'
        dependsOn: []
        policy: {}
        typeProperties: {
          source: {
            type: 'SqlSource'
            sqlReaderQuery: 'SELECT TABLE_SCHEMA, TABLE_NAME FROM information_schema.TABLES WHERE TABLE_TYPE = \'BASE TABLE\' and TABLE_SCHEMA = \'SalesLT\' and TABLE_NAME <> \'ProductModel\''
          }
          dataset: {
            referenceName: inputDatasetName
            type: 'DatasetReference'
            parameters: {}
          }
          firstRowOnly: false
        }
      }
      {
        name: 'TriggerCopy'
        type: 'ExecutePipeline'
        dependsOn: [
          {
            activity: 'LookupTableList'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        typeProperties: {
          pipeline: {
            referenceName: pipelineName
            type: 'PipelineReference'
          }
          parameters: {
            tableList: '@activity(\'LookupTableList\').output.value'
          }
        }
      }
    ]
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_inputDatasetName
    dataFactoryName_outputDatasetName
    dataFactoryName_pipelineName
  ]
}