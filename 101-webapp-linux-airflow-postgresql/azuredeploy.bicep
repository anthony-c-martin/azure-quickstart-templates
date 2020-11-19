param siteName string {
  metadata: {
    description: 'Name of Airflow web app'
  }
  default: 'airflow-${uniqueString(resourceGroup().id)}'
}
param servicePlanTier string {
  allowed: [
    'Standard'
    'Premium'
    'PremiumV2'
  ]
  metadata: {
    description: 'Tier for Service Plan'
  }
  default: 'PremiumV2'
}
param servicePlanSku string {
  allowed: [
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P1V2'
    'P2V2'
    'P3V3'
  ]
  metadata: {
    description: 'Size for Service Plan'
  }
  default: 'P1V2'
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
    'Basic'
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
param databaseSkuFamily string {
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

var databaseName = 'airflowdb'
var serverName_var = '${siteName}pgserver'
var AirflowUserName = '${administratorLogin}@${serverName_var}'
var hostingPlanName_var = '${siteName}serviceplan'

resource siteName_res 'Microsoft.Web/sites@2020-06-01' = {
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
  name: '${siteName}/appsettings'
  tags: {
    displayName: 'AirflowappSettings'
  }
  properties: {
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: 'postgresql://${AirflowUserName}:${administratorLoginPassword}@${serverName.properties.fullyQualifiedDomainName}:5432/${databaseName}'
    AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'true'
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