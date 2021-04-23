@description('Name of azure web app')
param siteName string

@allowed([
  'Basic'
  'Standard'
])
@description('Tier for Service Plan')
param servicePlanTier string = 'Basic'

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
])
@description('Size for Service Plan')
param servicePlanSku string = 'S2'

@minLength(6)
@maxLength(15)
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
@description('Azure database for MySQL compute capacity in vCores (2,4,8,16,32)')
param databaseSkuCapacity int = 2

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
])
@description('Azure database for MySQL sku name ')
param databaseSkuName string = 'GP_Gen5_2'

@allowed([
  102400
  51200
])
@description('Azure database for MySQL Sku Size ')
param databaseSkuSizeMB int = 51200

@allowed([
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Azure database for MySQL pricing tier')
param databaseSkuTier string = 'GeneralPurpose'

@allowed([
  '5.6'
  '5.7'
])
@description('MySQL version')
param mysqlVersion string = '5.7'

@description('Location for all the resources')
param location string = resourceGroup().location

@description('Azure database for MySQL sku family')
param databaseSkuFamily string = 'Gen5'

var databaseName = '${siteName}database'
var serverName_var = '${siteName}mysqlserver'
var jdbcSonarUserName = '${administratorLogin}@${serverName_var}'
var hostingPlanName_var = '${siteName}serviceplan'
var firewallrule = '${serverName_var}firewall'

resource siteName_resource 'Microsoft.Web/sites@2019-08-01' = {
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
  parent: siteName_resource
  name: 'appsettings'
  tags: {
    displayName: 'SonarappSettings'
  }
  properties: {
    SONARQUBE_JDBC_URL: 'jdbc:mysql://${serverName.properties.fullyQualifiedDomainName}:3306/${databaseName}?verifyServerCertificate=true&useSSL=true&requireSSL=false&useUnicode=true&characterEncoding=utf8'
    SONARQUBE_JDBC_USERNAME: jdbcSonarUserName
    SONARQUBE_JDBC_PASSWORD: administratorLoginPassword
  }
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
  parent: serverName
  location: location
  name: '${firewallrule}'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource serverName_databaseName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  parent: serverName
  name: '${databaseName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
  dependsOn: [
    serverName_firewallrule
  ]
}