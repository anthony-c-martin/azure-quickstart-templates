@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the dataset.')
param datasetName string

@description('Optional : The description for the dataset.')
param datasetDescription string = ''

@description('The  SQL/PostgreSQL/MySQL datastore name.')
param datastoreName string

@description('SQL Quey')
param sqlQuery string

@description('Optional : Column name to be used as FineGrainTimestamp')
param fineGrainTimestamp string = ''

@description('Optional : Column name to be used as CoarseGrainTimestamp. Can only be used if \'fineGrainTimestamp\' is specified and cannot be same as \'fineGrainTimestamp\'.')
param coarseGrainTimestamp string = ''

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
    datasetType: 'tabular'
    Parameters: {
      Query: {
        Query: sqlQuery
        DatastoreName: datastoreName
      }
      SourceType: 'sql_query'
    }
    Registration: {
      Description: datasetDescription
      Tags: tags
    }
    TimeSeries: {
      FineGrainTimestamp: fineGrainTimestamp
      CoarseGrainTimestamp: coarseGrainTimestamp
    }
  }
}