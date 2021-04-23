@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@description('The SQL server name.')
param sqlServerName string

@allowed([
  'SQL Authentication'
  'Service principal'
])
@description('Authentication type')
param authenticationType string = 'SQL Authentication'

@description('The username of the database user or service principal/application ID.')
param userNameOrClientId string

@description('The password of the database user or service principal\'s secret.')
@secure()
param passwordOrClientSecret string

@description('This is ignored if SQL Authentication is selected.')
param tenantId string = subscription().tenantId

@description('The database name.')
param databaseName string

@description('Optional : Authority url used to authenticate the user. Defaults to https://login.microsoftonline.com')
param authorityUrl string = ''

@description('Optional : Determines what operations will be performed on the database. Defaults to https://database.windows.net/')
param resourceUrl string = ''

@description('Optional : The endpoint of the sql server. Defaults to database.windows.net.')
param endpoint string = ''

@description('Optional : If set to true, the call will skip datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'sqldb'
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