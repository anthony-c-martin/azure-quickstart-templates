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
param accountName string {
  metadata: {
    description: 'The name of the storage account.'
  }
}
param fileSystem string {
  metadata: {
    description: 'The file system name of the ADLS Gen2.'
  }
}
param tenantId string {
  metadata: {
    description: 'The service principal Tenant ID.'
  }
  default: subscription().tenantId
}
param clientId string {
  metadata: {
    description: 'The service principal\'s client/application ID.'
  }
}
param clientSecret string {
  metadata: {
    description: 'The service principal\'s secret.'
  }
  secure: true
}
param resourceUrl string {
  metadata: {
    description: 'Optional : Determines what operations will be performed on the data lake store. Defaults to https://storage.azure.com/ allowing for filesystem operations.'
  }
  default: ''
}
param authorityUrl string {
  metadata: {
    description: 'Optional : Authority url used to authenticate the user. Defaults to https://login.microsoftonline.com'
  }
  default: ''
}
param skipValidation bool {
  metadata: {
    description: 'Optional : If set to true, the call will skip Datastore validation. Defaults to false'
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
    DataStoreType: 'adls-gen2'
    SkipValidation: skipValidation
    ClientId: clientId
    ClientSecret: clientSecret
    FileSystem: fileSystem
    AccountName: accountName
    TenantId: tenantId
    ResourceUrl: resourceUrl
    AuthorityUrl: authorityUrl
  }
}