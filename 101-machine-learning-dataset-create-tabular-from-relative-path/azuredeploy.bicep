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
param sourceType string {
  allowed: [
    'delimited_files'
    'json_lines_files'
    'parquet_files'
  ]
  metadata: {
    description: 'Data source type'
  }
  default: 'delimited_files'
}
param separator string {
  metadata: {
    description: 'Optional: The separator used to split columns for \'delimited_files\' sourceType, default to \',\' for \'delimited_files\''
  }
  default: ''
}
param header string {
  allowed: [
    'all_files_have_same_headers'
    'only_first_file_has_headers'
    'no_headers'
    'combine_all_files_headers'
  ]
  metadata: {
    description: 'Optional :  Header type. Defaults to \'all_files_have_same_headers\''
  }
  default: 'all_files_have_same_headers'
}
param partitionFormat string {
  metadata: {
    description: ' Optional : The partition information of each path will be extracted into columns based on the specified format. Format part \'{column_name}\' creates string column, and \'{column_name:yyyy/MM/dd/HH/mm/ss}\' creates datetime column, where \'yyyy\', \'MM\', \'dd\', \'HH\', \'mm\' and \'ss\' are used to extract year, month, day, hour, minute and second for the datetime type. The format should start from the position of first partition key until the end of file path. For example, given the path \'../USA/2019/01/01/data.parquet\' where the partition is by country/region and time, partition_format=\'/{CountryOrRegion}/{PartitionDate:yyyy/MM/dd}/data.csv\' creates a string column\'CountryOrRegion\' with the value \'USA\' and a datetime column \'PartitionDate\' with the value \'2019-01-01'
  }
  default: ''
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
param includePath bool {
  metadata: {
    description: 'Optional :  Boolean to keep path information as column in the dataset. Defaults to False. This is useful when reading multiple files, and want to know which file a particular record originated from, or to keep useful information in file path.'
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
      Header: header
      IncludePath: includePath
      PartitionFormat: partitionFormat
      Path: {
        DataPath: {
          RelativePath: relativePath
          DatastoreName: datastoreName
        }
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