param sqlServerName string {
  metadata: {
    description: 'The SQL Logical Server name.'
  }
  default: 'sql${uniqueString(resourceGroup().id)}'
}
param sqlAdministratorLogin string {
  metadata: {
    description: 'The administrator username of the SQL Server.'
  }
}
param sqlAdministratorPassword string {
  metadata: {
    description: 'The administrator password of the SQL Server.'
  }
  secure: true
}
param dataWarehouseName string {
  metadata: {
    description: 'The name of the Data Warehouse.'
  }
}
param transparentDataEncryption string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Enable/Disable Transparent Data Encryption'
  }
  default: 'Enabled'
}
param serviceLevelObjective string {
  metadata: {
    description: 'Performance Level'
  }
  default: 'DW400c'
}
param location string {
  metadata: {
    description: 'Resource location'
  }
  default: resourceGroup().location
}

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
  name: '${sqlServerName}/${dataWarehouseName}'
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
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_dataWarehouseName_current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2017-03-01-preview' = {
  name: '${sqlServerName}/${dataWarehouseName}/current'
  properties: {
    status: transparentDataEncryption
  }
  dependsOn: [
    sqlServerName_dataWarehouseName
  ]
}