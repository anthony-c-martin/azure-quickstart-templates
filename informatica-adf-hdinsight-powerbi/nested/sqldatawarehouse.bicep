@description('The location where all azure resources will be deployed.')
param location string = 'South Central US'

@description('SQL Datawarehouse Server Name, should be a unique name')
param sqlDWServerName string

@description('SQL Datawarehouse Admin Name')
param sqlDWDBAdminName string

@description('SQL Datawarehouse Admin password. Ex: Testadmin@123')
@secure()
param sqlDWAdminPassword string

@description('SQL Datawarehouse Database Name')
param sqlDWDBName string = 'testdwdb'
param serviceLevelObjective string = 'DW100'
param startIpAddress string = '0.0.0.0'
param endIpAddress string = '255.255.255.255'
param sql_api_version string = '2014-04-01'
param sqldb_api_version string = '2015-05-01-preview'
param sqlfirewallrules_api_version string = '2014-04-01'
param collation string = 'SQL_Latin1_General_CP1_CI_AS'
param maxSizeBytes string = '10995116277760'
param version string = '12.0'
param informaticaTags object
param quickstartTags object

resource sqlDWServerName_resource 'Microsoft.Sql/servers@2014-04-01' = {
  name: sqlDWServerName
  location: location
  tags: {
    displayName: 'VM Storage Accounts'
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    administratorLogin: sqlDWDBAdminName
    administratorLoginPassword: sqlDWAdminPassword
    version: version
  }
}

resource sqlDWServerName_sqlDWDBName 'Microsoft.Sql/servers/databases@[parameters(\'sqldb-api-version\')]' = {
  name: '${sqlDWServerName}/${sqlDWDBName}'
  location: location
  tags: {
    displayName: 'VM Storage Accounts'
    quickstartName: quickstartTags.name
    provider: informaticaTags.provider
  }
  properties: {
    edition: 'DataWarehouse'
    collation: collation
    maxSizeBytes: maxSizeBytes
    serviceLevelObjective: serviceLevelObjective
  }
  dependsOn: [
    sqlDWServerName_resource
  ]
}

resource sqlDWServerName_AllowAllAzureIps 'Microsoft.Sql/servers/firewallrules@[parameters(\'sqlfirewallrules-api-version\')]' = {
  location: location
  name: '${sqlDWServerName}/AllowAllAzureIps'
  properties: {
    endIpAddress: endIpAddress
    startIpAddress: startIpAddress
  }
  dependsOn: [
    sqlDWServerName_resource
  ]
}