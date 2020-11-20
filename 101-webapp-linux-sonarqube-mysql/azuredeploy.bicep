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
  default: 'Basic'
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
  minLength: 6
  maxLength: 15
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
param databaseSkuCapacity int {
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
  default: '5.7'
}
param location string {
  metadata: {
    description: 'Location for all the resources'
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
var serverName_var = '${siteName}mysqlserver'
var jdbcSonarUserName = '${administratorLogin}@${serverName_var}'
var hostingPlanName_var = '${siteName}serviceplan'
var firewallrule = '${serverName_var}firewall'

resource siteName_res 'Microsoft.Web/sites@2019-08-01' = {
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

resource siteName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${siteName}/appsettings'
  tags: {
    displayName: 'SonarappSettings'
  }
  properties: {
    SONARQUBE_JDBC_URL: 'jdbc:mysql://${serverName.properties.fullyQualifiedDomainName}:3306/${databaseName}?verifyServerCertificate=true&useSSL=true&requireSSL=false&useUnicode=true&characterEncoding=utf8'
    SONARQUBE_JDBC_USERNAME: jdbcSonarUserName
    SONARQUBE_JDBC_PASSWORD: administratorLoginPassword
  }
  dependsOn: [
    siteName_res
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
    tier: servicePlanTier
    name: servicePlanSku
  }
  kind: 'linux'
}

resource serverName 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: serverName_var
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
    capacity: databaseSkuCapacity
    size: databaseSkuSizeMB
    family: databaseSkuFamily
  }
  properties: {
    version: mysqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageMB: databaseSkuSizeMB
  }
}

resource serverName_firewallrule 'Microsoft.DBforMySQL/servers/firewallrules@2017-12-01' = {
  location: location
  name: '${serverName_var}/${firewallrule}'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    serverName
  ]
}

resource serverName_databaseName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  name: '${serverName_var}/${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
  dependsOn: [
    serverName
    serverName_firewallrule
  ]
}