param siteName string {
  metadata: {
    description: 'Name of azure web app'
  }
}
param appServicePlanName string {
  metadata: {
    description: 'Name of hosting plan'
  }
}
param skuTier string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'SKU tier'
  }
  default: 'Free'
}
param skuName string {
  allowed: [
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
  ]
  metadata: {
    description: 'SKU Name'
  }
  default: 'F1'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource appServicePlanName_res 'Microsoft.Web/serverfarms@2015-08-01' = {
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

resource siteName_res 'Microsoft.Web/sites@2015-08-01' = {
  name: siteName
  location: location
  properties: {
    name: siteName
    serverFarmId: appServicePlanName
  }
  dependsOn: [
    appServicePlanName_res
  ]
}

resource siteName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${siteName}/web'
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
  dependsOn: [
    siteName_res
  ]
}

resource siteName_appsettings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${siteName}/appsettings'
  properties: {
    SCM_SITEEXTENSIONS_FEED_URL: 'http://www.siteextensions.net/api/v2/'
  }
  dependsOn: [
    siteName_res
  ]
}

resource siteName_GoLang 'Microsoft.Web/sites/siteextensions@2015-08-01' = {
  name: '${siteName}/GoLang'
  properties: {}
  dependsOn: [
    siteName_res
    siteName_web
  ]
}