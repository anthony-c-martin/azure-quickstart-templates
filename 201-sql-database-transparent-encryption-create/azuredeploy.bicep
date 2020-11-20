param sqlAdministratorLogin string {
  metadata: {
    description: 'The administrator username of the SQL Server.'
  }
}
param sqlAdministratorLoginPassword string {
  metadata: {
    description: 'The administrator password of the SQL Server.'
  }
  secure: true
}
param transparentDataEncryption string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'Enable or disable Transparent Data Encryption (TDE) for the database.'
  }
  default: 'Enabled'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var sqlServerName_var = 'sqlserver${uniqueString(subscription().id, resourceGroup().id)}'
var databaseName_var = 'sample-db-with-tde'
var databaseEdition = 'Basic'
var databaseCollation = 'SQL_Latin1_General_CP1_CI_AS'
var databaseServiceObjectiveName = 'Basic'

resource sqlServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlServerName_var
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlServerName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${sqlServerName_var}/${databaseName_var}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: databaseEdition
    collation: databaseCollation
    requestedServiceObjectiveName: databaseServiceObjectiveName
  }
  dependsOn: [
    sqlServerName
  ]
}

resource sqlServerName_databaseName_current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2017-03-01-preview' = {
  name: '${sqlServerName_var}/${databaseName_var}/current'
  properties: {
    status: transparentDataEncryption
  }
  dependsOn: [
    sqlServerName_databaseName
  ]
}

resource sqlServerName_AllowAllMicrosoftAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  name: '${sqlServerName_var}/AllowAllMicrosoftAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlServerName
  ]
}

output sqlServerFqdn string = sqlServerName.properties.fullyQualifiedDomainName
output databaseName string = databaseName_var