@description('The SQL Logical Server name.')
param sqlServerName string = 'sql${uniqueString(resourceGroup().id)}'

@description('The administrator username of the SQL Server.')
param sqlAdministratorLogin string

@description('The administrator password of the SQL Server.')
@secure()
param sqlAdministratorPassword string

@description('The name of the Data Warehouse.')
param dataWarehouseName string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Enable/Disable Transparent Data Encryption')
param transparentDataEncryption string = 'Enabled'

@description('Performance Level')
param serviceLevelObjective string = 'DW400c'

@description('Resource location')
param location string = resourceGroup().location

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    version: '12.0'
  }
}

resource sqlServerName_dataWarehouseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServerName_resource
  name: '${dataWarehouseName}'
  location: location
  kind: 'v12.0,user,datawarehouse'
  properties: {
    edition: 'DataWarehouse'
    status: 'Online'
    requestedServiceObjectiveName: serviceLevelObjective
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    readScale: 'Disabled'
    zoneRedundant: false
    isUpgradeRequested: false
  }
}

resource sqlServerName_dataWarehouseName_current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2017-03-01-preview' = {
  parent: sqlServerName_dataWarehouseName
  name: 'current'
  properties: {
    status: transparentDataEncryption
  }
}