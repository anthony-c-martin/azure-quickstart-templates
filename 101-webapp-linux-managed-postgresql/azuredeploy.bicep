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
    description: 'Azure database for PostgreSQL vCores capacity'
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
    'B_Gen5_1'
    'B_Gen5_2'
  ]
  metadata: {
    description: 'Azure database for PostgreSQL sku name : '
  }
  default: 'GP_Gen5_2'
}
param databaseSkuSizeMB int {
  allowed: [
    102400
    51200
  ]
  metadata: {
    description: 'Azure database for PostgreSQL Sku Size '
  }
  default: 51200
}
param databaseSkuTier string {
  allowed: [
    'GeneralPurpose'
    'MemoryOptimized'
    'Basic'
  ]
  metadata: {
    description: 'Azure database for PostgreSQL pricing tier'
  }
  default: 'GeneralPurpose'
}
param postgresqlVersion string {
  allowed: [
    '9.5'
    '9.6'
  ]
  metadata: {
    description: 'PostgreSQL version'
  }
  default: '9.6'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var databaseName = '${siteName}database'
var serverName = '${siteName}pgserver'
var hostingPlanName = '${siteName}serviceplan'

resource siteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: siteName
  properties: {
    siteConfig: {
      linuxFxVersion: 'node|6.10'
      connectionStrings: [
        {
          name: 'defaultConnection'
          ConnectionString: 'Database=${databaseName};Server=${serverName_resource.properties.fullyQualifiedDomainName};User Id=${administratorLogin}@${serverName};Password=${administratorLoginPassword}'
          type: 'PostgreSQL'
        }
      ]
    }
    name: siteName
    serverFarmId: hostingPlanName
  }
  location: location
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
  location: location
  properties: {
    name: hostingPlanName
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: '1'
  }
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
  kind: 'linux'
}

resource serverName_resource 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  location: location
  name: serverName
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
  location: location
  name: '${serverName}/${serverName}firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    serverName_resource
  ]
}

resource serverName_databaseName 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: '${serverName}/${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'English_United States.1252'
  }
  dependsOn: [
    serverName_resource
  ]
}