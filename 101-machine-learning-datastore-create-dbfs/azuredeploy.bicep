@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@allowed([
  false
  true
])
@description('Optional : If set to true, the call will skip Datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'DBFS'
    SkipValidation: skipValidation
  }
}