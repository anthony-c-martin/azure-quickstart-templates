@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@description('The MySQL server name.')
param serverName string

@description('The database name.')
param databaseName string

@description('The user ID.')
param userId string

@description('The password.')
@secure()
param password string

@description('Optional : The port number. Defaults to 3306')
param port string = ''

@description('Optional : The endpoint of the server. Defaults to mysql.database.azure.com.')
param endpoint string = ''

@description('Optional : If set to true, the call will skip Datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'mysqldb'
    SkipValidation: skipValidation
    DatabaseName: databaseName
    Password: password
    ServerName: serverName
    UserId: userId
    Port: port
    Endpoint: endpoint
  }
}