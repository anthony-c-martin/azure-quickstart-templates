param dataFactoryName string {
  metadata: {
    description: 'Data Factory Name'
  }
  default: 'datafactory${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location of the data factory. Currently, only East US, East US 2, and West Europe are supported.'
  }
  default: resourceGroup().location
}
param storageAccountName string {
  metadata: {
    description: 'Name of the Azure storage account that contains the input/output data.'
  }
  default: 'storage${uniqueString(resourceGroup().id)}'
}
param blobContainer string {
  metadata: {
    description: 'Name of the blob container in the Azure Storage account.'
  }
  default: 'blob${uniqueString(resourceGroup().id)}'
}

var storageAccountId = storageAccountName_res.id
var storageLinkedService = dataFactoryName_ArmtemplateStorageLinkedService.id
var datasetIn = dataFactoryName_ArmtemplateTestDatasetIn.id
var datasetOut = dataFactoryName_ArmtemplateTestDatasetOut.id

resource storageAccountName_res 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource storageAccountName_default_blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName}/default/${blobContainer}'
  dependsOn: [
    storageAccountName_res
  ]
}

resource dataFactoryName_res 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  properties: {}
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryName_ArmtemplateStorageLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  name: '${dataFactoryName}/ArmtemplateStorageLinkedService'
  location: location
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
    }
  }
  dependsOn: [
    dataFactoryName_res
  ]
}

resource dataFactoryName_ArmtemplateTestDatasetIn 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactoryName}/ArmtemplateTestDatasetIn'
  location: location
  properties: {
    linkedServiceName: {
      referenceName: 'ArmtemplateStorageLinkedService'
      type: 'LinkedServiceReference'
    }
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainer
        folderPath: 'input'
        fileName: 'emp.txt'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
    storageLinkedService
  ]
}

resource dataFactoryName_ArmtemplateTestDatasetOut 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactoryName}/ArmtemplateTestDatasetOut'
  location: location
  properties: {
    linkedServiceName: {
      referenceName: 'ArmtemplateStorageLinkedService'
      type: 'LinkedServiceReference'
    }
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainer
        folderPath: 'output'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
    storageLinkedService
  ]
}

resource dataFactoryName_ArmtemplateSampleCopyPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${dataFactoryName}/ArmtemplateSampleCopyPipeline'
  location: location
  properties: {
    activities: [
      {
        name: 'MyCopyActivity'
        type: 'Copy'
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        typeProperties: {
          source: {
            type: 'BinarySource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
            }
          }
          sink: {
            type: 'BinarySink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
            }
          }
          enableStaging: false
        }
        inputs: [
          {
            referenceName: 'ArmtemplateTestDatasetIn'
            type: 'DatasetReference'
            parameters: {}
          }
        ]
        outputs: [
          {
            referenceName: 'ArmtemplateTestDatasetOut'
            type: 'DatasetReference'
            parameters: {}
          }
        ]
      }
    ]
  }
  dependsOn: [
    dataFactoryName_res
    datasetIn
    datasetOut
  ]
}