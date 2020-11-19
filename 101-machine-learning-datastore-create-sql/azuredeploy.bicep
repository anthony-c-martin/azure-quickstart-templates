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
param sqlServerName string {
  metadata: {
    description: 'The SQL server name.'
  }
}
param authenticationType string {
  allowed: [
    'SQL Authentication'
    'Service principal'
  ]
  metadata: {
    description: 'Authentication type'
  }
  default: 'SQL Authentication'
}
param userNameOrClientId string {
  metadata: {
    description: 'The username of the database user or service principal/application ID.'
  }
}
param passwordOrClientSecret string {
  metadata: {
    description: 'The password of the database user or service principal\'s secret.'
  }
  secure: true
}
param tenantId string {
  metadata: {
    description: 'This is ignored if SQL Authentication is selected.'
  }
  default: subscription().tenantId
}
param databaseName string {
  metadata: {
    description: 'The database name.'
  }
}
param authorityUrl string {
  metadata: {
    description: 'Optional : Authority url used to authenticate the user. Defaults to https://login.microsoftonline.com'
  }
  default: ''
}
param resourceUrl string {
  metadata: {
    description: 'Optional : Determines what operations will be performed on the database. Defaults to https://database.windows.net/'
  }
  default: ''
}
param endpoint string {
  metadata: {
    description: 'Optional : The endpoint of the sql server. Defaults to database.windows.net.'
  }
  default: ''
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
    DataStoreType: 'sqldb'
    SkipValidation: skipValidation
    DatabaseName: databaseName
    ServerName: sqlServerName
    UserName: ((authenticationType == 'SQL Authentication') ? userNameOrClientId : json('null'))
    Password: ((authenticationType == 'SQL Authentication') ? passwordOrClientSecret : json('null'))
    TenantId: ((authenticationType == 'Service principal') ? tenantId : json('null'))
    ClientId: ((authenticationType == 'Service principal') ? userNameOrClientId : json('null'))
    ClientSecret: ((authenticationType == 'Service principal') ? passwordOrClientSecret : json('null'))
    AuthorityUrl: authorityUrl
    ResourceUrl: resourceUrl
    Endpoint: endpoint
  }
}