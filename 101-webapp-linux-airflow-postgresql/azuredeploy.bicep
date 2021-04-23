@description('Name of Airflow web app')
param siteName string = 'airflow-${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard'
  'Premium'
  'PremiumV2'
])
@description('Tier for Service Plan')
param servicePlanTier string = 'PremiumV2'

@allowed([
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P1V2'
  'P2V2'
  'P3V3'
])
@description('Size for Service Plan')
param servicePlanSku string = 'P1V2'

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
  'B_Gen5_1'
  'B_Gen5_2'
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
@description('Azure database for PostgreSQL sku name ')
param databaseSkuName string = 'GP_Gen5_2'

@allowed([
  102400
  51200
])
@description('Azure database for PostgreSQL Sku Size ')
param databaseSkuSizeMB int = 51200

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Azure database for PostgreSQL pricing tier')
param databaseSkuTier string = 'GeneralPurpose'

@allowed([
  '9.5'
  '9.6'
])
@description('PostgreSQL version')
param postgresqlVersion string = '9.6'

@description('Azure database for PostgreSQL sku family')
param databaseSkuFamily string = 'Gen5'

@description('Location for all the resources.')
param location string = resourceGroup().location

var databaseName = 'airflowdb'
var serverName_var = '${siteName}pgserver'
var AirflowUserName = '${administratorLogin}@${serverName_var}'
var hostingPlanName_var = '${siteName}serviceplan'

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|puckel/docker-airflow:latest'
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
  parent: siteName_resource
  name: 'appsettings'
  tags: {
    displayName: 'AirflowappSettings'
  }
  properties: {
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: 'postgresql://${AirflowUserName}:${administratorLoginPassword}@${serverName.properties.fullyQualifiedDomainName}:5432/${databaseName}'
    AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'true'
  }
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
    family: databaseSkuFamily
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