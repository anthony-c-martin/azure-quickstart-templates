@description('Name of azure web app')
param siteName string

@minLength(1)
@description('Database administrator login name')
param administratorLogin string

@minLength(8)
@maxLength(128)
@description('Database administrator password')
@secure()
param administratorLoginPassword string

@allowed([
  2
  4
  8
  16
  32
])
@description('Azure database for PostgreSQL compute capacity in vCores (2,4,8,16,32)')
param databaseSkuCapacity int = 2

@allowed([
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_8'
  'GP_Gen5_16'
  'GP_Gen5_32'
  'MO_Gen5_2'
  'MO_Gen5_4'
  'MO_Gen5_8'
  'MO_Gen5_16'
  'MO_Gen5_32'
  'B_Gen5_1'
  'B_Gen5_2'
])
@description('Azure database for PostgreSQL sku name ')
param databaseSkuName string = 'GP_Gen5_2'

@allowed([
  102400
  51200
])
@description('Azure database for PostgreSQL Sku Size ')
param databaseSkuSizeMB int = 51200

@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
  'Basic'
])
@description('Azure database for PostgreSQL pricing tier')
param databaseSkuTier string = 'GeneralPurpose'

@allowed([
  '9.5'
  '9.6'
  '10.10'
  '11.5'
])
@description('PostgreSQL version')
param postgresqlVersion string = '9.6'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Azure database for PostgreSQL sku family')
param databaseskuFamily string = 'Gen5'

var databaseName = '${siteName}database'
var serverName_var = '${siteName}pgserver'
var hostingPlanName_var = '${siteName}serviceplan'

resource hostingPlanName 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName_var
  location: location
  properties: {
    name: hostingPlanName_var
    workerSize: '1'
    numberOfWorkers: 0
  }
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
}

resource siteName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: hostingPlanName_var
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource siteName_connectionstrings 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: siteName_resource
  name: 'connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Database=${databaseName};Server=${serverName.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName_var};Password=${administratorLoginPassword}'
      type: 'PostgreSQL'
    }
  }
}

resource serverName 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  location: location
  name: serverName_var
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseSkuCapacity
    size: databaseSkuSizeMB
    family: databaseskuFamily
  }
  properties: {
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageMB: databaseSkuSizeMB
  }
}

resource serverName_serverName_firewall 'Microsoft.DBforPostgreSQL/servers/firewallrules@2017-12-01' = {
  parent: serverName
  location: location
  name: '${serverName_var}firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource serverName_databaseName 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: serverName
  name: '${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'English_United States.1252'
  }
}