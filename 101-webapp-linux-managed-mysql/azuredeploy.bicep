@description('The unique name of your Web Site.')
param siteName string = 'MySQL-${uniqueString(resourceGroup().name)}'

@minLength(1)
@description('Database administrator login name')
param administratorLogin string

@minLength(8)
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
@description('Azure database for mySQL compute capacity in vCores (2,4,8,16,32)')
param dbSkucapacity int = 2

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
])
@description('Azure database for mySQL sku name ')
param dbSkuName string = 'GP_Gen5_2'

@allowed([
  102400
  51200
])
@description('Azure database for mySQL Sku Size ')
param dbSkuSizeMB int = 51200

@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Azure database for mySQL pricing tier')
param dbSkuTier string = 'GeneralPurpose'

@allowed([
  '5.6'
  '5.7'
])
@description('MySQL version')
param mysqlVersion string = '5.7'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Azure database for mySQL sku family')
param databaseskuFamily string = 'Gen5'

var databaseName = 'database${uniqueString(resourceGroup().id)}'
var serverName_var = 'mysql-${uniqueString(resourceGroup().id)}'
var hostingPlanName_var = 'hpn-${uniqueString(resourceGroup().id)}'

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    tier: 'Standard'
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    name: hostingPlanName_var
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: '1'
  }
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'php|7.0'
      connectionStrings: [
        {
          name: 'defaultConnection'
          connectionString: 'Database=${databaseName};Data Source=${serverName.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName_var};Password=${administratorLoginPassword}'
          type: 'MySql'
        }
      ]
    }
    name: siteName
    serverFarmId: hostingPlanName_var
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource serverName 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName_var
  location: location
  sku: {
    name: dbSkuName
    tier: dbSkuTier
    capacity: dbSkucapacity
    size: dbSkuSizeMB
    family: databaseskuFamily
  }
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: dbSkuSizeMB
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
  }
}

resource serverName_AllowAzureIPs 'Microsoft.DBforMySQL/servers/firewallrules@2017-12-01' = {
  parent: serverName
  name: 'AllowAzureIPs'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    serverName_databaseName
  ]
}

resource serverName_databaseName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  parent: serverName
  name: '${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}