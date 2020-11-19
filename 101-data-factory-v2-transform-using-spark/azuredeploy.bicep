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
    description: 'Location of the data factory. Currently, only East US and East US 2 are supported. '
  }
  default: 'East US'
}
param azureStorageConnectionString string {
  metadata: {
    description: 'Connection string for the Azure Storage account.'
  }
}
param servicePrincipalId string {
  metadata: {
    description: 'The ID of the service principal that has permissions to create HDInsight clusters in your subscription.'
  }
}
param servicePrincipalKey string {
  metadata: {
    description: 'The access key of the service principal that has permissions to create HDInsight clusters in your subscription.'
  }
}

var azureStorageLinkedServiceName = 'Tutorial4_AzureStorageLinkedService'
var onDemandHDInsightLinkedServiceName = 'Tutorial4_OnDemandHDInsightLinkedService'
var pipelineName = 'Tutorial4_SparkPipeline'
var scriptRootPath = 'adftutorial/spark/script'
var entryFilePath = 'WordCount_Spark.py'

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

resource dataFactoryName_onDemandHDInsightLinkedServiceName 'Microsoft.DataFactory/factories/linkedservices@2017-09-01-preview' = {
  name: '${dataFactoryName}/${onDemandHDInsightLinkedServiceName}'
  properties: {
    type: 'HDInsightOnDemand'
    typeProperties: {
      clusterType: 'spark'
      clusterSize: 4
      timeToLive: '00:05:00'
      clusterResourceGroup: resourceGroup().name
      tenant: subscription().tenantId
      sparkVersion: ''
      servicePrincipalId: servicePrincipalId
      servicePrincipalKey: {
        type: 'SecureString'
        value: servicePrincipalKey
      }
      linkedServiceName: {
        referenceName: azureStorageLinkedServiceName
        type: 'LinkedServiceReference'
      }
    }
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_azureStorageLinkedServiceName
  ]
}

resource dataFactoryName_pipelineName 'Microsoft.DataFactory/factories/pipelines@2017-09-01-preview' = {
  name: '${dataFactoryName}/${pipelineName}'
  properties: {
    activities: [
      {
        name: 'MySparkActivity'
        type: 'HDInsightSpark'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
        }
        typeProperties: {
          rootPath: scriptRootPath
          entryFilePath: entryFilePath
          arguments: []
          sparkJobLinkedService: {
            referenceName: azureStorageLinkedServiceName
            type: 'LinkedServiceReference'
          }
        }
        linkedServiceName: {
          referenceName: onDemandHDInsightLinkedServiceName
          type: 'LinkedServiceReference'
        }
      }
    ]
  }
  dependsOn: [
    dataFactoryName_res
    dataFactoryName_azureStorageLinkedServiceName
    dataFactoryName_onDemandHDInsightLinkedServiceName
  ]
}