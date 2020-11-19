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
    description: 'The datastore name.'
  }
}
param relativePath string {
  metadata: {
    description: 'Path within the datastore'
  }
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
    datasetType: 'file'
    Parameters: {
      Path: {
        DataPath: {
          RelativePath: relativePath
          DatastoreName: datastoreName
        }
      }
    }
    Registration: {
      Description: datasetDescription
      Tags: tags
    }
  }
}