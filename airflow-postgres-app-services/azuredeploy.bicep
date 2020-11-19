param airflowWebAppName string {
  metadata: {
    description: 'Name of Airflow web app'
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
param databaseSkuCapacity int {
  allowed: [
    1
    2
    4
    8
    16
    32
  ]
  metadata: {
    description: 'Azure database for PostgreSQL compute capacity in vCores (1, 2, 4, 8, 16, 32)'
  }
  default: 1
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
    'B_Gen5_1'
    'B_Gen5_2'
  ]
  metadata: {
    description: 'Azure database for PostgreSQL sku name '
  }
  default: 'B_Gen5_1'
}
param databaseSkuSizeMB int {
  allowed: [
    102400
    51200
    10240
    5120
  ]
  metadata: {
    description: 'Azure database for PostgreSQL Sku Size '
  }
  default: 5120
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
  default: 'Basic'
}
param databaseskuFamily string {
  metadata: {
    description: 'Azure database for PostgreSQL sku family'
  }
  default: 'Gen5'
}
param postgresqlVersion string {
  allowed: [
    '9.5'
    '9.6'
    '10'
    '11'
  ]
  metadata: {
    description: 'PostgreSQL version'
  }
  default: '11'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var databaseName = '${airflowWebAppName}database'
var serverName = '${airflowWebAppName}pgserver'
var hostingPlanName = '${airflowWebAppName}serviceplan'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName
  location: location
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
  properties: {
    name: hostingPlanName
    workerSize: '1'
    reserved: true
    numberOfWorkers: 1
  }
}

resource airflowWebAppName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: airflowWebAppName
  location: location
  properties: {
    serverFarmId: hostingPlanName
    name: airflowWebAppName
    siteConfig: {
      linuxFxVersion: 'DOCKER|puckel/docker-airflow:latest'
      requestTracingEnabled: true
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      autoHealEnabled: true
    }
    httpsOnly: true
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource airflowWebAppName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${airflowWebAppName}/appsettings'
  tags: {
    displayName: 'Airflow App Settings'
  }
  properties: {
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: 'postgresql://${administratorLogin}:${administratorLoginPassword}@${serverName_resource.properties.fullyQualifiedDomainName}:5432/${databaseName}'
    AIRFLOW__CORE__SQL_ALCHEMY_POOL_SIZE: 20
    AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    AIRFLOW__CORE__EXECUTOR: 'LocalExecutor'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'true'
  }
  dependsOn: [
    airflowWebAppName_resource
  ]
}

resource serverName_resource 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverName
  location: location
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
  name: '${serverName}/${serverName}firewall'
  location: location
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