param siteName string {
  metadata: {
    description: 'Name of azure web app'
  }
}
param administratorLogin string {
  minLength: 1
  metadata: {
    description: 'Database administrator login name'
  }
}
param administratorLoginPassword string {
  minLength: 8
  maxLength: 128
  metadata: {
    description: 'Database administrator password'
  }
  secure: true
}
param databaseSkucapacity int {
  allowed: [
    2
    4
    8
    16
    32
  ]
  metadata: {
    description: 'Azure database for MySQL compute capacity in vCores (2,4,8,16,32)'
  }
  default: 2
}
param databaseSkuName string {
  allowed: [
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
  ]
  metadata: {
    description: 'Azure database for MySQL sku name '
  }
  default: 'GP_Gen5_2'
}
param databaseSkuSizeMB int {
  allowed: [
    102400
    51200
  ]
  metadata: {
    description: 'Azure database for MySQL Sku Size '
  }
  default: 51200
}
param databaseSkuTier string {
  allowed: [
    'GeneralPurpose'
    'MemoryOptimized'
  ]
  metadata: {
    description: 'Azure database for MySQL pricing tier'
  }
  default: 'GeneralPurpose'
}
param mysqlVersion string {
  allowed: [
    '5.6'
    '5.7'
  ]
  metadata: {
    description: 'MySQL version'
  }
  default: '5.6'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param databaseSkuFamily string {
  metadata: {
    description: 'Azure database for MySQL sku family'
  }
  default: 'Gen5'
}

var databaseName = '${siteName}database'
var serverName = '${siteName}myserver'
var hostingPlanName = '${siteName}serviceplan'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  properties: {
    name: hostingPlanName
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: 0
  }
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: hostingPlanName
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource siteName_connectionstrings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${siteName}/connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Database=${databaseName};Data Source=${serverName_resource.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName};Password=${administratorLoginPassword}'
      type: 'MySql'
    }
  }
  dependsOn: [
    siteName_resource
  ]
}

resource serverName_resource 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  location: location
  name: serverName
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseSkucapacity
    size: databaseSkuSizeMB
    family: databaseSkuFamily
  }
  properties: {
    createMode: 'Default'
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: databaseSkuSizeMB
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
  }
}

resource serverName_AllowAzureIPs 'Microsoft.DBforMySQL/servers/firewallrules@2017-12-01' = {
  location: location
  name: '${serverName}/AllowAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
  dependsOn: [
    serverName_databaseName
    serverName_resource
  ]
}

resource serverName_databaseName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  name: '${serverName}/${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
  dependsOn: [
    serverName_resource
  ]
}