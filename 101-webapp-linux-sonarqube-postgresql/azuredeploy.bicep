param siteName string {
  metadata: {
    description: 'Name of azure web app'
  }
}
param servicePlanTier string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'Tier for Service Plan'
  }
  default: 'Standard'
}
param servicePlanSku string {
  allowed: [
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
  ]
  metadata: {
    description: 'Size for Service Plan'
  }
  default: 'S2'
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
param databaseSkuCapacity int {
  allowed: [
    2
    4
    8
    16
    32
  ]
  metadata: {
    description: 'Azure database for PostgreSQL compute capacity in vCores (2,4,8,16,32)'
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
    description: 'Azure database for PostgreSQL sku name '
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
param databaseskuFamily string {
  metadata: {
    description: 'Azure database for PostgreSQL sku family'
  }
  default: 'Gen5'
}
param location string {
  metadata: {
    description: 'Location for all the resources.'
  }
  default: resourceGroup().location
}

var databaseName = '${siteName}database'
var serverName_var = '${siteName}pgserver'
var jdbcSonarUserName = '${administratorLogin}@${serverName_var}'
var hostingPlanName_var = '${siteName}serviceplan'

resource siteName_res 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|SONARQUBE'
    }
    name: siteName
    serverFarmId: hostingPlanName_var
  }
  dependsOn: [
    hostingPlanName
    serverName_databaseName
  ]
}

resource siteName_appsettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${siteName}/appsettings'
  tags: {
    displayName: 'SonarappSettings'
  }
  properties: {
    SONARQUBE_JDBC_URL: 'jdbc:postgresql://${serverName.properties.fullyQualifiedDomainName}:5432/${databaseName}?user=${jdbcSonarUserName}&password=${administratorLoginPassword}&ssl=true'
    SONARQUBE_JDBC_USERNAME: jdbcSonarUserName
    SONARQUBE_JDBC_PASSWORD: administratorLoginPassword
  }
  dependsOn: [
    siteName_res
  ]
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  properties: {
    name: hostingPlanName_var
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: '1'
  }
  sku: {
    tier: servicePlanTier
    name: servicePlanSku
  }
  kind: 'linux'
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
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageMB: databaseSkuSizeMB
  }
}

resource serverName_serverName_firewall 'Microsoft.DBforPostgreSQL/servers/firewallrules@2017-12-01' = {
  location: location
  name: '${serverName_var}/${serverName_var}firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    serverName
  ]
}

resource serverName_databaseName 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: '${serverName_var}/${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'English_United States.1252'
  }
  dependsOn: [
    serverName
  ]
}