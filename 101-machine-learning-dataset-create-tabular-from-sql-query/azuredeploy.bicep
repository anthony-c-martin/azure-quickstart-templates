param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.'
  }
}
param datasetName string {
  metadata: {
    description: 'The name of the dataset.'
  }
}
param datasetDescription string {
  metadata: {
    description: 'Optional : The description for the dataset.'
  }
  default: ''
}
param datastoreName string {
  metadata: {
    description: 'The  SQL/PostgreSQL/MySQL datastore name.'
  }
}
param sqlQuery string {
  metadata: {
    description: 'SQL Quey'
  }
}
param fineGrainTimestamp string {
  metadata: {
    description: 'Optional : Column name to be used as FineGrainTimestamp'
  }
  default: ''
}
param coarseGrainTimestamp string {
  metadata: {
    description: 'Optional : Column name to be used as CoarseGrainTimestamp. Can only be used if \'fineGrainTimestamp\' is specified and cannot be same as \'fineGrainTimestamp\'.'
  }
  default: ''
}
param tags object {
  metadata: {
    description: 'Optional : Provide JSON object with \'key,value\' pairs to add as tags on dataset. Example- {"sampleTag1": "tagValue1", "sampleTag2": "tagValue2"}'
  }
  default: {}
}
param skipValidation bool {
  metadata: {
    description: 'Optional :  Skip validation that ensures data can be loaded from the dataset before registration.'
  }
  default: false
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}

resource workspaceName_datasetName 'Microsoft.MachineLearningServices/workspaces/datasets@2020-05-01-preview' = {
  name: '${workspaceName}/${datasetName}'
  location: location
  properties: {
    SkipValidation: skipValidation
    DatasetType: 'tabular'
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