param storageAccountName string {
  metadata: {
    description: 'Name of the Azure Storage'
  }
}
param storageAccountKey string {
  metadata: {
    description: 'Key associated with the corresponding Azure Storage'
  }
  secure: true
}
param SfUserName string {
  metadata: {
    description: 'User Name associated with Salesforce account'
  }
}
param SfPassword string {
  metadata: {
    description: 'Password associated with the corresponding Salesforce account'
  }
  secure: true
}
param SfSecurityToken string {
  metadata: {
    description: 'Password associated with the corresponding Salesforce account'
  }
  secure: true
}
param SfTable string {
  metadata: {
    description: 'Salesforce Object from where to copy the data from'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var dataFactoryName_var = 'SalesforceToAzureBlobDF${uniqueString(resourceGroup().id)}'
var SfLinkedServiceName = 'SflLinkedService'
var storageLinkedServiceName = 'StorageLinkedService'
var SfDataset = 'SfDataset'
var StorageDataset = 'StorageContainerDataset'
var PipelineName = 'SftoBlobsCopyPipeline'

resource dataFactoryName 'Microsoft.DataFactory/datafactories@2015-10-01' = {
  name: dataFactoryName_var
  location: location
}

resource dataFactoryName_SfLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName_var}/${SfLinkedServiceName}'
  properties: {
    type: 'Salesforce'
    description: 'SalesForce Linked Service'
    typeProperties: {
      username: SfUserName
      password: SfPassword
      securityToken: SfSecurityToken
    }
  }
  dependsOn: [
    dataFactoryName
  ]
}

resource dataFactoryName_storageLinkedServiceName 'Microsoft.DataFactory/datafactories/linkedservices@2015-10-01' = {
  name: '${dataFactoryName_var}/${storageLinkedServiceName}'
  properties: {
    type: 'AzureStorage'
    description: 'Azure Blobs Storage Linked Service'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
  dependsOn: [
    dataFactoryName
  ]
}

resource dataFactoryName_SfDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName_var}/${SfDataset}'
  properties: {
    type: 'RelationalTable'
    linkedServiceName: SfLinkedServiceName
    typeProperties: {
      tableName: SfTable
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: true
  }
  dependsOn: [
    dataFactoryName
    dataFactoryName_SfLinkedServiceName
  ]
}

resource dataFactoryName_StorageDataset 'Microsoft.DataFactory/datafactories/datasets@2015-10-01' = {
  name: '${dataFactoryName_var}/${StorageDataset}'
  properties: {
    type: 'AzureBlob'
    linkedServiceName: storageLinkedServiceName
    typeProperties: {
      folderPath: 'datafromsftable/{Year}/{Month}/{Day}/Data.csv'
      partitionedBy: [
        {
          name: 'Year'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: 'yyyy'
          }
        }
        {
          name: 'Month'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: '%M'
          }
        }
        {
          name: 'Day'
          value: {
            type: 'DateTime'
            date: 'SliceStart'
            format: '%d'
          }
        }
      ]
      format: {
        type: 'TextFormat'
      }
    }
    availability: {
      frequency: 'Day'
      interval: 1
    }
    external: false
  }
  dependsOn: [
    dataFactoryName
    dataFactoryName_storageLinkedServiceName
  ]
}

resource dataFactoryName_PipelineName 'Microsoft.DataFactory/datafactories/datapipelines@2015-10-01' = {
  name: '${dataFactoryName_var}/${PipelineName}'
  properties: {
    description: 'Pipeline to copy data from SF Object to Azure Blobs'
    activities: [
      {
        name: 'SftoBlobsCopyActivity'
        description: 'Copies data from SF Table to Azure Blobs'
        type: 'Copy'
        inputs: [
          {
            name: SfDataset
          }
        ]
        outputs: [
          {
            name: StorageDataset
          }
        ]
        typeProperties: {
          source: {
            type: 'RelationalSource'
          }
          sink: {
            type: 'BlobSink'
          }
        }
        Policy: {
          retry: 3
          timeout: '00:30:00'
        }
      }
    ]
    start: '10/1/2016 12:00:00 AM'
    end: '10/1/2016 12:00:00 AM'
  }
  dependsOn: [
    dataFactoryName
    dataFactoryName_storageLinkedServiceName
    dataFactoryName_SfLinkedServiceName
    dataFactoryName_SfDataset
    dataFactoryName_StorageDataset
  ]
}