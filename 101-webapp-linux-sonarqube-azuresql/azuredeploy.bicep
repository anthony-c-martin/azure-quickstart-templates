@description('Name of Azure Web App')
param siteName string = 'sonarqube-${uniqueString(resourceGroup().id)}'

@allowed([
  '7.7-community'
  '7.6-community'
  '7.5-community'
  '7.4-community'
  '7.1'
  '7.1-alpine'
  '7.0'
  '7.0-alpine'
  '6.7.5'
  '6.7.5-alpine'
  '6.7.4'
  '6.7.4-alpine'
  '6.7.3'
  '6.7.3-alpine'
  '6.7.2'
  '6.7.2-alpine'
  '6.7.1'
  '6.7.1-alpine'
])
@description('The version of the Sonarqube container image to use. Only versions of Sonarqube known to be compatible with Azure App Service Web App for Containers are available.')
param sonarqubeImageVersion string = '7.7-community'

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1V2'
  'P2V2'
  'P2V3'
])
@description('App Service Plan Pricing Tier')
param servicePlanPricingTier string = 'S2'

@minValue(1)
@maxValue(3)
@description('App Service Capacity')
param servicePlanCapacity int = 1

@minLength(1)
@description('Azure SQL Server Administrator Username')
param sqlServerAdministratorUsername string

@minLength(12)
@maxLength(128)
@description('Azure SQL Server Administrator Password')
@secure()
param sqlServerAdministratorPassword string

@allowed([
  'GP_Gen4_1'
  'GP_Gen4_2'
  'GP_Gen4_3'
  'GP_Gen4_4'
  'GP_Gen4_5'
  'GP_Gen4_6'
  'GP_Gen4_7'
  'GP_Gen4_8'
  'GP_Gen4_9'
  'GP_Gen4_10'
  'GP_Gen4_16'
  'GP_Gen4_24'
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_6'
  'GP_Gen5_8'
  'GP_Gen5_10'
  'GP_Gen5_12'
  'GP_Gen5_14'
  'GP_Gen5_16'
  'GP_Gen5_18'
  'GP_Gen5_20'
  'GP_Gen5_24'
  'GP_Gen5_32'
  'GP_Gen5_40'
  'GP_Gen5_80'
  'GP_S_Gen5_1'
  'GP_S_Gen5_2'
  'GP_S_Gen5_4'
])
@description('Azure SQL Database SKU Name')
param sqlDatabaseSkuName string = 'GP_S_Gen5_2'

@minValue(1)
@maxValue(1024)
@description('Azure SQL Database Storage Max Size in GB')
param sqlDatabaseSkuSizeGB int = 16

@description('Location for all the resources.')
param location string = resourceGroup().location

var databaseName = 'sonarqube'
var sqlServerName_var = '${siteName}-sql'
var servicePlanName_var = '${siteName}-asp'
var servicePlanPricingTiers = {
  F1: {
    tier: 'Free'
  }
  B1: {
    tier: 'Basic'
  }
  B2: {
    tier: 'Basic'
  }
  B3: {
    tier: 'Basic'
  }
  S1: {
    tier: 'Standard'
  }
  S2: {
    tier: 'Standard'
  }
  S3: {
    tier: 'Standard'
  }
  P1V2: {
    tier: 'Standard'
  }
  P2V2: {
    tier: 'Standard'
  }
  P2V3: {
    tier: 'Standard'
  }
}
var sqlDatabaseServerlessTiers = [
  'GP_S_Gen5_1'
  'GP_S_Gen5_2'
  'GP_S_Gen5_4'
]

resource servicePlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: servicePlanName_var
  location: location
  properties: {
    name: servicePlanName_var
    workerSizeId: '1'
    reserved: true
    numberOfWorkers: '1'
  }
  sku: {
    name: servicePlanPricingTier
    tier: servicePlanPricingTiers[servicePlanPricingTier].tier
    capacity: servicePlanCapacity
  }
  kind: 'linux'
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|sonarqube:${sonarqubeImageVersion}'
    }
    name: siteName
    serverFarmId: servicePlanName_var
  }
  dependsOn: [
    servicePlanName
    sqlServerName
  ]
}

resource siteName_appsettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: siteName_resource
  name: 'appsettings'
  tags: {
    displayName: 'SonarappSettings'
  }
  properties: {
    SONARQUBE_JDBC_URL: 'jdbc:sqlserver://${sqlServerName.properties.fullyQualifiedDomainName};databaseName=${databaseName};encrypt=true;trustServerCertificate=false;hostNameInCertificate=${replace(sqlServerName.properties.fullyQualifiedDomainName, '${sqlServerName_var}.', '*.')};loginTimeout=30;'
    SONARQUBE_JDBC_USERNAME: sqlServerAdministratorUsername
    SONARQUBE_JDBC_PASSWORD: sqlServerAdministratorPassword
    'sonar.path.data': '/home/sonarqube/data'
  }
}

resource sqlServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  location: location
  name: sqlServerName_var
  kind: 'v12.0'
  properties: {
    administratorLogin: sqlServerAdministratorUsername
    administratorLoginPassword: sqlServerAdministratorPassword
    version: '12.0'
  }
}

resource sqlServerName_sqlServerName_firewall 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  parent: sqlServerName
  location: location
  name: '${sqlServerName_var}firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServerName
  name: '${databaseName}'
  location: location
  sku: {
    name: sqlDatabaseSkuName
    tier: 'GeneralPurpose'
  }
  kind: 'v12.0,user,vcore${(contains(sqlDatabaseServerlessTiers, sqlDatabaseSkuName) ? ',serverless' : '')}'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CS_AS'
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: (((sqlDatabaseSkuSizeGB * 1024) * 1024) * 1024)
  }
}