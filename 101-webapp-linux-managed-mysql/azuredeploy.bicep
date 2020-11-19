param siteName string {
  metadata: {
    description: 'The unique name of your Web Site.'
  }
  default: 'MySQL-${uniqueString(resourceGroup().name)}'
}
param administratorLogin string {
  minLength: 1
  metadata: {
    description: 'Database administrator login name'
  }
}
param administratorLoginPassword string {
  minLength: 8
  metadata: {
    description: 'Database administrator password'
  }
  secure: true
}
param dbSkucapacity int {
  allowed: [
    2
    4
    8
    16
    32
  ]
  metadata: {
    description: 'Azure database for mySQL compute capacity in vCores (2,4,8,16,32)'
  }
  default: 2
}
param dbSkuName string {
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
    description: 'Azure database for mySQL sku name '
  }
  default: 'GP_Gen5_2'
}
param dbSkuSizeMB int {
  allowed: [
    102400
    51200
  ]
  metadata: {
    description: 'Azure database for mySQL Sku Size '
  }
  default: 51200
}
param dbSkuTier string {
  allowed: [
    'GeneralPurpose'
    'MemoryOptimized'
  ]
  metadata: {
    description: 'Azure database for mySQL pricing tier'
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
  default: '5.7'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param databaseskuFamily string {
  metadata: {
    description: 'Azure database for mySQL sku family'
  }
  default: 'Gen5'
}

var databaseName = 'database${uniqueString(resourceGroup().id)}'
var serverName = 'mysql-${uniqueString(resourceGroup().id)}'
var hostingPlanName = 'hpn-${uniqueString(resourceGroup().id)}'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
  kind: 'linux'
  properties: {
    name: hostingPlanName
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
          ConnectionString: 'Database=${databaseName};Data Source=${serverName_resource.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName};Password=${administratorLoginPassword}'
          type: 'MySql'
        }
      ]
    }
    name: siteName
    serverFarmId: hostingPlanName
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource serverName_resource 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName
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
  name: '${serverName}/AllowAzureIPs'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
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