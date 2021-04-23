@description('Name of azure web app')
param siteName string

@description('Name of hosting plan')
param appServicePlanName string

@allowed([
  'Free'
  'Shared'
  'Basic'
  'Standard'
  'Premium'
])
@description('SKU tier')
param skuTier string = 'Free'

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
])
@description('SKU Name')
param skuName string = 'F1'

@description('Location for all resources.')
param location string = resourceGroup().location

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: appServicePlanName
  location: location
  properties: {
    name: appServicePlanName
  }
  sku: {
    name: skuName
    tier: skuTier
    capacity: 1
  }
}

resource siteName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: appServicePlanName
  }
  dependsOn: [
    appServicePlanName_resource
  ]
}

resource siteName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: siteName_resource
  name: 'web'
  properties: {
    phpVersion: 'off'
    netFrameworkVersion: 'v4.5'
    webSocketsEnabled: true
    requestTracingEnabled: true
    httpLoggingEnabled: true
    logsDirectorySizeLimit: 40
    detailedErrorLoggingEnabled: true
    scmType: 'LocalGit'
  }
}

resource siteName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: siteName_resource
  name: 'appsettings'
  properties: {
    SCM_SITEEXTENSIONS_FEED_URL: 'http://www.siteextensions.net/api/v2/'
  }
}

resource siteName_GoLang 'Microsoft.Web/sites/siteextensions@2015-08-01' = {
  parent: siteName_resource
  name: 'GoLang'
  properties: {}
  dependsOn: [
    siteName_web
  ]
}