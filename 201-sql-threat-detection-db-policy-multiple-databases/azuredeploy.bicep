@description('Name for the SQL server')
param serverName string = 'server-${uniqueString(resourceGroup().id)}'

@description('Array of names for the SQL databases')
param databaseNames array = [
  'db-${uniqueString(resourceGroup().id)}-1'
  'db-${uniqueString(resourceGroup().id)}-2'
]

@description('Location for server and DBs')
param location string = resourceGroup().location

@description('Username for admin')
param adminUser string

@description('Password for admin')
@secure()
param adminPassword string

var databaseServerName_var = toLower(serverName)
var databaseNames_var = databaseNames
var databaseServerLocation = location
var databaseServerAdminLogin = adminUser
var databaseServerAdminLoginPassword = adminPassword

resource databaseServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  location: databaseServerLocation
  name: databaseServerName_var
  properties: {
    administratorLogin: databaseServerAdminLogin
    administratorLoginPassword: databaseServerAdminLoginPassword
    version: '12.0'
  }
  tags: {
    DisplayName: databaseServerName_var
  }
}

resource databaseServerName_databaseNames 'Microsoft.Sql/servers/databases@2020-02-02-preview' = [for item in databaseNames_var: {
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  kind: 'v12.0,user'
  location: databaseServerLocation
  name: '${string(databaseServerName_var)}/${string(item)}'
  tags: {
    DisplayName: databaseServerName_var
  }
  properties: {}
  dependsOn: [
    databaseServerName
  ]
}]

resource databaseServerName_databaseNames_default 'Microsoft.Sql/servers/databases/securityAlertPolicies@2020-02-02-preview' = [for item in databaseNames_var: {
  name: '${string(databaseServerName_var)}/${string(item)}/default'
  properties: {
    state: 'Enabled'
  }
  dependsOn: [
    resourceId('Microsoft.Sql/servers/databases', databaseServerName_var, item)
  ]
}]