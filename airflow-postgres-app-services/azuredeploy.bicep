@description('Name of Airflow web app')
param airflowWebAppName string

@minLength(1)
@description('Database administrator login name')
param administratorLogin string

@minLength(8)
@maxLength(128)
@description('Database administrator password')
@secure()
param administratorLoginPassword string

@allowed([
  1
  2
  4
  8
  16
  32
])
@description('Azure database for PostgreSQL compute capacity in vCores (1, 2, 4, 8, 16, 32)')
param databaseSkuCapacity int = 1

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
param databaseSkuName string = 'B_Gen5_1'

@allowed([
  102400
  51200
  10240
  5120
])
@description('Azure database for PostgreSQL Sku Size ')
param databaseSkuSizeMB int = 5120

@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
  'Basic'
])
@description('Azure database for PostgreSQL pricing tier')
param databaseSkuTier string = 'Basic'

@description('Azure database for PostgreSQL sku family')
param databaseskuFamily string = 'Gen5'

@allowed([
  '9.5'
  '9.6'
  '10'
  '11'
])
@description('PostgreSQL version')
param postgresqlVersion string = '11'

@description('Location for all resources.')
param location string = resourceGroup().location

var databaseName = '${airflowWebAppName}database'
var serverName_var = '${airflowWebAppName}pgserver'
var hostingPlanName_var = '${airflowWebAppName}serviceplan'

resource hostingPlanName 'Microsoft.Web/serverfarms@2018-11-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    Tier: 'Standard'
    Name: 'S1'
  }
  properties: {
    name: hostingPlanName_var
    workerSize: '1'
    reserved: true
    numberOfWorkers: 1
  }
}

resource airflowWebAppName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: airflowWebAppName
  location: location
  properties: {
    serverFarmId: hostingPlanName_var
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
    hostingPlanName
  ]
}

resource airflowWebAppName_appsettings 'Microsoft.Web/sites/config@2019-08-01' = {
  parent: airflowWebAppName_resource
  name: 'appsettings'
  tags: {
    displayName: 'Airflow App Settings'
  }
  properties: {
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: 'postgresql://${administratorLogin}:${administratorLoginPassword}@${serverName.properties.fullyQualifiedDomainName}:5432/${databaseName}'
    AIRFLOW__CORE__SQL_ALCHEMY_POOL_SIZE: 20
    AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    AIRFLOW__CORE__EXECUTOR: 'LocalExecutor'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'true'
  }
}

resource serverName 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverName_var
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
  parent: serverName
  name: '${serverName_var}firewall'
  location: location
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