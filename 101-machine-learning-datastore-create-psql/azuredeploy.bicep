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
param serverName string {
  metadata: {
    description: 'The PostgreSQL server name.'
  }
}
param databaseName string {
  metadata: {
    description: 'The database name.'
  }
}
param userId string {
  metadata: {
    description: 'The user ID.'
  }
}
param password string {
  metadata: {
    description: 'The password.'
  }
  secure: true
}
param port string {
  metadata: {
    description: 'Optional : The port number. Defaults to 5432'
  }
  default: ''
}
param endpoint string {
  metadata: {
    description: 'Optional : The endpoint of the server. Defaults to postgres.database.azure.com.'
  }
  default: ''
}
param enforceSSL bool {
  metadata: {
    description: 'Optional : This sets the ssl value of the server. Defaults to true if not set.'
  }
  default: true
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
    DataStoreType: 'psqldb'
    SkipValidation: skipValidation
    DatabaseName: databaseName
    Password: password
    ServerName: serverName
    UserId: userId
    Port: port
    Endpoint: endpoint
    EnforceSSL: enforceSSL
  }
}