@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The Http URL.')
param httpUrl string

@description('The name of the dataset.')
param datasetName string

@description('Optional : The description for the dataset.')
param datasetDescription string = ''

@description('Optional : Provide JSON object with \'key,value\' pairs to add as tags on dataset. Example- {"sampleTag1": "tagValue1", "sampleTag2": "tagValue2"}')
param tags object = {}

@description('Optional :  Skip validation that ensures data can be loaded from the dataset before registration.')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datasetName 'Microsoft.MachineLearningServices/workspaces/datasets@2020-05-01-preview' = {
  name: '${workspaceName}/${datasetName}'
  location: location
  properties: {
    SkipValidation: skipValidation
    datasetType: 'file'
    Parameters: {
      Path: {
        HttpUrl: httpUrl
      }
    }
    Registration: {
      Description: datasetDescription
      Tags: tags
    }
  }
}