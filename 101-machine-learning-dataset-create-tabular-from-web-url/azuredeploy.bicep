@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The Http URL.')
param httpUrl string

@description('The name of the dataset.')
param datasetName string

@description('Optional : The description for the dataset.')
param datasetDescription string = ''

@allowed([
  'delimited_files'
  'json_lines_files'
  'parquet_files'
])
@description('Data source type')
param sourceType string = 'delimited_files'

@description('Optional: The separator used to split columns for \'delimited_files\' sourceType, default to \',\' for \'delimited_files\'')
param separator string = ''

@allowed([
  'all_files_have_same_headers'
  'only_first_file_has_headers'
  'no_headers'
  'combine_all_files_headers'
])
@description('Optional :  Header type. Defaults to \'all_files_have_same_headers\'')
param header string = 'all_files_have_same_headers'

@description('Optional : Column name to be used as FineGrainTimestamp')
param fineGrainTimestamp string = ''

@description('Optional : Column name to be used as CoarseGrainTimestamp. Can only be used if \'fineGrainTimestamp\' is specified and cannot be same as \'fineGrainTimestamp\'.')
param coarseGrainTimestamp string = ''

@description('Optional : Provide JSON object with \'key,value\' pairs to add as tags on dataset. Example- {"sampleTag1": "tagValue1", "sampleTag2": "tagValue2"}')
param tags object = {}

@description('Optional :  Skip validation that ensures data can be loaded from the dataset before registration.')
param skipValidation bool = false

@description('Optional :  Boolean to keep path information as column in the dataset. Defaults to False. This is useful when reading multiple files, and want to know which file a particular record originated from, or to keep useful information in file path.')
param includePath bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datasetName 'Microsoft.MachineLearningServices/workspaces/datasets@2020-05-01-preview' = {
  name: '${workspaceName}/${datasetName}'
  location: location
  properties: {
    SkipValidation: skipValidation
    datasetType: 'tabular'
    Parameters: {
      Header: header
      IncludePath: includePath
      Path: {
        HttpUrl: httpUrl
      }
      Separator: separator
      SourceType: sourceType
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