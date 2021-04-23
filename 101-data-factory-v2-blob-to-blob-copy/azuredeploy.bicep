@description('Data Factory Name')
param dataFactoryName string = 'datafactory${uniqueString(resourceGroup().id)}'

@description('Location of the data factory. Currently, only East US, East US 2, and West Europe are supported.')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainer string = 'blob${uniqueString(resourceGroup().id)}'

var storageAccountId = storageAccountName_resource.id
var storageLinkedService = dataFactoryName_ArmtemplateStorageLinkedService.id
var datasetIn = dataFactoryName_ArmtemplateTestDatasetIn.id
var datasetOut = dataFactoryName_ArmtemplateTestDatasetOut.id

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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
    storageAccountName_resource
  ]
}

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  properties: {}
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryName_ArmtemplateStorageLinkedService 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryName_resource
  name: 'ArmtemplateStorageLinkedService'
  location: location
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[0].value}'
    }
  }
}

resource dataFactoryName_ArmtemplateTestDatasetIn 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryName_resource
  name: 'ArmtemplateTestDatasetIn'
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
    storageLinkedService
  ]
}

resource dataFactoryName_ArmtemplateTestDatasetOut 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryName_resource
  name: 'ArmtemplateTestDatasetOut'
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
    storageLinkedService
  ]
}

resource dataFactoryName_ArmtemplateSampleCopyPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactoryName_resource
  name: 'ArmtemplateSampleCopyPipeline'
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
    datasetIn
    datasetOut
  ]
}