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
@description('Azure database for PostgreSQL vCores capacity')
param databaseSkucapacity int = 2

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
  'B_Gen5_1'
  'B_Gen5_2'
])
@description('Azure database for PostgreSQL sku name : ')
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
])
@description('PostgreSQL version')
param postgresqlVersion string = '9.6'

@description('Location for all resources.')
param location string = resourceGroup().location

var databaseName = '${siteName}database'
var serverName_var = '${siteName}pgserver'
var hostingPlanName_var = '${siteName}serviceplan'

resource siteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: siteName
  properties: {
    siteConfig: {
      linuxFxVersion: 'node|6.10'
      connectionStrings: [
        {
          name: 'defaultConnection'
          connectionString: 'Database=${databaseName};Server=${serverName.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName_var};Password=${administratorLoginPassword}'
          type: 'PostgreSQL'
        }
      ]
    }
    name: siteName
    serverFarmId: hostingPlanName_var
  }
  location: location
  dependsOn: [
    hostingPlanName
  ]
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  properties: {
    name: hostingPlanName_var
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: '1'
  }
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: 'linux'
}

resource serverName 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  location: location
  name: serverName_var
  properties: {
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageMB: databaseSkuSizeMB
  }
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseSkucapacity
    size: databaseSkuSizeMB
    family: 'Gen5'
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