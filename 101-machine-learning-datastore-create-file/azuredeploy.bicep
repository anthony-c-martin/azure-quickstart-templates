param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.'
  }
}
param datastoreName string {
  metadata: {
    description: 'The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore'
  }
}
param storageAccountName string {
  metadata: {
    description: 'The name of the storage account.'
  }
}
param fileShareName string {
  metadata: {
    description: 'The name of the file share.'
  }
}
param authenticationType string {
  allowed: [
    'SAS token'
    'Account Key'
  ]
  metadata: {
    description: 'Authentication type'
  }
  default: 'SAS token'
}
param sasTokenOrAccountKey string {
  metadata: {
    description: 'Storage account SAS token or Account Key'
  }
  secure: true
}
param skipValidation bool {
  metadata: {
    description: 'Optional : If set to true, the call will skip datastore validation. Defaults to false'
  }
  default: false
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    DataStoreType: 'file'
    SkipValidation: skipValidation
    AccountName: storageAccountName
    ShareName: fileShareName
    AccountKey: ((authenticationType == 'Account Key') ? sasTokenOrAccountKey : json('null'))
    SasToken: ((authenticationType == 'SAS token') ? sasTokenOrAccountKey : json('null'))
  }
}